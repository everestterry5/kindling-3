import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { MonitorStore, MONITOR_INTERVAL_MS as DAY, MONITOR_RETENTION_MS } from '../monitoring-store.mjs';
import { createMonitoringService, changedEvidence, validateMonitorEnrollment } from '../monitoring.mjs';
import { SECTION_IDS } from '../analysis.mjs';
import { createServer } from '../server.mjs';
const body = () => ({ clientId: 'untrusted-install', signedTransaction: 'private-apple-proof', consent: true,
 idea: { id: randomUUID(), title: 'Garden', summary: 'Shared garden plots for neighborhood apartment residents', customer: 'Apartment residents', problem: 'No growing space', businessModel: 'Membership', category: 'Local service' },
 founder: { budget: 'private budget', hours: 'private hours', skills: 'private skills', experience: 'private experience', distribution: 'private contacts', region: 'Chicago' } });
function fixture(t, { enabled = true, dailyLimit = 100 } = {}) {
 const dir=mkdtempSync(join(tmpdir(),'kindling-monitor-'));const path=join(dir,'monitors.json');t.after(()=>rmSync(dir,{recursive:true,force:true}));
 let time=Date.UTC(2026,9,13,12),version=1;const now=()=>time;
 const state={search:0,model:0,apple:0,meaningful:true,invalidCitations:false,searchFailure:false,badReport:false,appleError:null,hold:null,scoreReason:true};
 const apple={ready:true,verify:async proof=>{state.apple++;if(state.appleError)throw Object.assign(new Error('Unverified'),{status:state.appleError});return {environment:'Sandbox',originalTransactionId:proof,expiresAt:now()+7*DAY};}};
 const env={MONITORING_ENABLED:String(enabled),MONITORING_FILE:path,MONITORING_DAILY_LIMIT:String(dailyLimit),PRO_PURCHASES_ENABLED:'true',DEEPSEEK_API_KEY:'fake',DEEPSEEK_MODEL:'fake-model',TAVILY_API_KEY:'fake'};
 const fetchImpl=async(url,options)=>{
  const request=JSON.parse(options.body);
  if(url.includes('tavily')){
   state.search++;assert.ok(!request.query.includes('private'));
   if(state.hold)await state.hold;if(state.searchFailure)throw new Error('secret search failure');
   const topic=request.query.endsWith('customer demand market evidence')?'market':request.query.endsWith('competitors alternatives pricing product changes')?'competitors':'trends';
   return {ok:true,json:async()=>({results:[{url:`https://example.org/${topic}`,title:`${topic} evidence`,content:`Dated ${topic} evidence version ${version}`,published_date:'2026-10-12'}]})};
  }
  assert.equal(url,'https://api.deepseek.com/chat/completions');state.model++;assert.ok(!options.body.includes('private-apple-proof'));
  const comparison=request.messages[0].content.startsWith('Compare business research evidence');
  const raw=comparison?{changed:state.meaningful,summary:state.meaningful?'New evidence identifies a competitor offer to validate; this is a research lead.':'',confidence:'medium',sourceURLs:state.meaningful?[state.invalidCitations?'https://invented.example':'https://example.org/competitors']:[]}:
   {sections:SECTION_IDS.map(id=>({id,headline:`Assessment ${id}`,body:state.scoreReason?'New sourced evidence changes an assumption to test.':'Unsupported proposed score is now 99.',score:['readiness','entry','fit'].includes(id)?50+version:null,confidence:'medium',actions:['Check the source'],unknowns:['Willingness to pay'],sourceURLs:['https://example.org/competitors'],...(state.scoreReason?{scoreChangeReason:'The newly sourced competitor offer narrows the positioning assumption used in this planning estimate.'}:{})}))};
  if(!comparison&&state.badReport)raw.sections.pop();
  return {ok:true,json:async()=>({choices:[{finish_reason:'stop',message:{content:JSON.stringify(raw)}}]})};
 };
 const store=new MonitorStore(path,{now,dailyLimit});const service=createMonitoringService({env,apple,fetchImpl,now,store,logger:{error(){}}});
 return {service,store,path,state,env,apple,fetchImpl,now,advance:(ms=DAY)=>{time+=ms;},change:()=>{version++;}};
}
test('consent, bounded inputs and signed Apple proof required; client reports/scores are ignored',()=>{
 const value=body();assert.equal(validateMonitorEnrollment(value).idea.id,value.idea.id);
 for(const bad of [{...value,consent:false},{...value,signedTransaction:''},{...value,isPro:true},{...value,founder:{...value.founder,budget:'x'.repeat(1001)}}])assert.throws(()=>validateMonitorEnrollment(bad),{status:400});
 const clean=validateMonitorEnrollment({...value,report:{score:99},idea:{...value.idea,viabilityScore:99}});assert.equal(clean.report,undefined);assert.equal(clean.idea.viabilityScore,undefined);assert.equal(clean.clientId,undefined);
});
test('disabled or missing production store performs no Apple/search/model calls',async t=>{
 const f=fixture(t,{enabled:false});await f.service.tick();await assert.rejects(f.service.enroll(body()),{status:503});assert.deepEqual([f.state.apple,f.state.search,f.state.model],[0,0,0]);
 assert.equal(createMonitoringService({env:{...f.env,NODE_ENV:'production',MONITORING_FILE:undefined,MONITORING_ENABLED:'true'},apple:f.apple,fetchImpl:f.fetchImpl}).ready,false);
});
test('one idea per subscription; token rotation recovers without resetting due; token hashes only on disk',async t=>{
 const f=fixture(t),input=body(),enrolled=await f.service.enroll(input);assert.equal(enrolled.status,'active');assert.equal(enrolled.report,undefined);
 assert.throws(()=>f.service.status({id:enrolled.id,token:'wrong'}),{status:404});await assert.rejects(f.service.enroll({...input,idea:{...input.idea,id:randomUUID()}}),{status:409});
 await f.service.tick();const before=f.service.status(enrolled),renewed=await f.service.enroll(input);assert.equal(renewed.id,enrolled.id);assert.notEqual(renewed.token,enrolled.token);assert.equal(renewed.nextCheckAt,before.nextCheckAt);assert.throws(()=>f.service.status(enrolled),{status:404});
 const saved=readFileSync(f.path,'utf8');assert.ok(!saved.includes(renewed.token));assert.ok(!saved.includes(input.clientId));assert.equal(statSync(f.path).mode&0o777,0o600);
});
test('first baseline and unchanged daily evidence use exactly three searches each and never rescore',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();assert.deepEqual([f.state.search,f.state.model],[3,0]);await f.service.tick();assert.equal(f.state.search,3);
 f.advance();await f.service.tick();assert.deepEqual([f.state.search,f.state.model],[6,0]);const result=f.service.status(enrolled);assert.equal(result.events.length,0);assert.equal(result.report,undefined);assert.match(result.message,/No meaningful/);
});
test('meaningful evidence produces cited report and server-only score history; founder fit does not drift',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll({...body(),report:{score:99}});await f.service.tick();f.advance();f.change();await f.service.tick();
 let result=f.service.status(enrolled);if(process.env.WRITE_MONITORING_FIXTURE==='true'){writeFileSync(new URL('./monitoring-enrollment-fixture.json',import.meta.url),JSON.stringify(enrolled,null,2)+'\n');writeFileSync(new URL('./monitoring-response-fixture.json',import.meta.url),JSON.stringify(result,null,2)+'\n');}assert.equal(f.state.model,2);assert.equal(result.events[0].score,52);assert.equal(result.events[0].previousScore,undefined);assert.equal(result.report.sections.length,13);assert.deepEqual(result.events[0].sources.map(s=>s.url),['https://example.org/competitors']);assert.equal(result.events[0].sources[0].excerpt,undefined);
 f.advance();f.change();await f.service.tick();result=f.service.status(enrolled);assert.equal(result.events[0].previousScore,52);assert.equal(result.events[0].score,53);assert.equal(result.report.sections.find(s=>s.id==='fit').score,52);assert.match(result.events[0].summary,/Planning readiness estimate/);
 f.advance();f.change();f.state.scoreReason=false;await f.service.tick();result=f.service.status(enrolled);assert.equal(result.events[0].score,53,'No sourced reason means no arbitrary numerical drift');assert.ok(!result.report.sections.find(s=>s.id==='readiness').body.includes('99'));assert.ok(!result.report.sections.find(s=>s.id==='fit').body.includes('99'));
});
test('novel but nonmaterial evidence does not trigger an assessment',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();f.advance();f.change();f.state.meaningful=false;await f.service.tick();assert.equal(f.state.model,1);assert.equal(f.service.status(enrolled).events.length,0);
});
test('failed searches, invented citations and malformed reports preserve previous evidence and assessment',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();const prior=structuredClone(f.store.data.monitors[enrolled.id].evidence);
 f.advance();f.change();f.state.searchFailure=true;await f.service.tick();assert.equal(f.state.model,0);assert.deepEqual(f.store.data.monitors[enrolled.id].evidence,prior);
 f.advance();f.state.searchFailure=false;f.state.invalidCitations=true;await f.service.tick();assert.equal(f.state.model,1);assert.equal(f.service.status(enrolled).events.length,0);
 f.advance();f.state.invalidCitations=false;f.state.badReport=true;await f.service.tick();assert.equal(f.service.status(enrolled).events.length,0);assert.deepEqual(f.store.data.monitors[enrolled.id].evidence,prior);
});
test('order, whitespace, publication metadata and removed results alone are not new evidence',()=>{
 const a={url:'https://example.org/a',title:'Research',excerpt:'Measured demand',publishedAt:'old'},b={url:'https://example.org/b',title:'Other',excerpt:'Other evidence'};
 assert.deepEqual(changedEvidence({sources:[a,b]},{sources:[{...a,title:' research ',excerpt:'Measured   demand',publishedAt:'new'}]}),[]);
});
test('restart/delete/re-enroll cannot reset owner 24-hour cost cap or global budget',async t=>{
 const f=fixture(t,{dailyLimit:1}),input=body(),enrolled=await f.service.enroll(input);await f.service.tick();f.service.remove(enrolled);
 const store=new MonitorStore(f.path,{now:f.now,dailyLimit:1}),service=createMonitoringService({env:f.env,apple:f.apple,fetchImpl:f.fetchImpl,now:f.now,store,logger:{error(){}}});
 const replacement=await service.enroll({...input,idea:{...input.idea,id:randomUUID()}});assert.ok(Date.parse(replacement.nextCheckAt)>f.now());await service.tick();assert.equal(f.state.search,3);
 const other=await service.enroll({...body(),signedTransaction:'another-original'});await service.tick();assert.equal(f.state.search,3);assert.match(service.status(other).message,/budget/);
});
test('queued owners get a chance when daily global cap resets',async t=>{
 const f=fixture(t,{dailyLimit:1}),first=await f.service.enroll(body()),second=await f.service.enroll({...body(),signedTransaction:'another-original'});await f.service.tick();assert.notEqual(f.service.status(first).lastCheckedAt,null);assert.equal(f.service.status(second).lastCheckedAt,null);
 f.advance(DAY/2);await f.service.tick();assert.notEqual(f.service.status(second).lastCheckedAt,null);assert.equal(f.state.search,6);
});
test('new idea/founder input clears old evidence but preserves due',async t=>{
 const f=fixture(t),input=body(),enrolled=await f.service.enroll(input);await f.service.tick();const due=f.service.status(enrolled).nextCheckAt;
 const edited=await f.service.enroll({...input,founder:{...input.founder,region:'Austin'}});assert.equal(edited.nextCheckAt,due);assert.equal(f.store.data.monitors[edited.id].evidence,null);await f.service.tick();assert.equal(f.state.search,3);
});
test('overlapping ticks run once; delete during search prevents resurrection and further model spend',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();f.advance();f.change();let release;f.state.hold=new Promise(resolve=>{release=resolve;});
 const ticking=f.service.tick();await new Promise(resolve=>setImmediate(resolve));await f.service.tick();f.service.remove(enrolled);release();await ticking;assert.equal(f.state.search,6);assert.equal(f.state.model,0);assert.throws(()=>f.service.status(enrolled),{status:404});assert.equal(Object.keys(f.store.data.monitors).length,0);
});
test('expired/revoked Apple access stops before search; outage does not become a market event',async t=>{
 const f=fixture(t),input=body(),enrolled=await f.service.enroll(input);f.state.appleError=403;await f.service.tick();assert.equal(f.state.search,0);assert.equal(f.service.status(enrolled).status,'expired');assert.equal(f.store.data.monitors[enrolled.id].signedTransaction,'');
 await assert.rejects(f.service.enroll(input),{status:403});f.state.appleError=null;const renewed=await f.service.enroll(input);assert.equal(renewed.status,'active');f.advance();f.state.appleError=503;await f.service.tick();assert.equal(f.state.search,0);assert.match(f.service.status(renewed).message,/could not complete/);
});
test('paused data purges at thirty days; deletion is retry-safe but an existing monitor requires token',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());assert.throws(()=>f.service.remove({id:enrolled.id,token:'wrong'}),{status:404});assert.equal(f.service.status(enrolled).id,enrolled.id);
 const paused=createMonitoringService({env:{...f.env,MONITORING_ENABLED:'false'},apple:f.apple,fetchImpl:f.fetchImpl,now:f.now,store:f.store});await paused.tick();assert.equal(paused.status(enrolled).status,'paused');f.advance(MONITOR_RETENTION_MS);await paused.tick();assert.throws(()=>paused.status(enrolled),{status:404});assert.deepEqual(paused.remove(enrolled),{deleted:true});assert.ok(!readFileSync(f.path,'utf8').includes('private-apple-proof'));
 writeFileSync(f.path,'{broken');assert.throws(()=>new MonitorStore(f.path));
});
test('history bounded to ten; status refresh never runs paid research',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();for(let i=0;i<12;i++){f.advance();f.change();await f.service.tick();}const counts=[f.state.search,f.state.model];assert.equal(f.service.status(enrolled).events.length,10);for(let i=0;i<5;i++)f.service.status(enrolled);assert.deepEqual([f.state.search,f.state.model],counts);
});
test('HTTP monitoring routes report readiness, authenticate status, and allow retry-safe stop',async t=>{
 const f=fixture(t),server=createServer({env:f.env,apple:f.apple,fetchImpl:f.fetchImpl,monitoring:f.service,logger:{error(){}}});await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));t.after(()=>new Promise(resolve=>server.close(resolve)));
 const base=`http://127.0.0.1:${server.address().port}`,post=(action,value)=>fetch(`${base}/v1/monitoring/${action}`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(value)});
 assert.equal((await(await fetch(`${base}/health`)).json()).monitoringReady,true);const enrolled=await(await post('enroll',body())).json();assert.equal(enrolled.token.length,43);assert.equal((await post('status',{id:enrolled.id,token:'bad'})).status,404);assert.equal((await(await post('status',enrolled)).json()).token,undefined);assert.deepEqual(await(await post('delete',enrolled)).json(),{deleted:true});assert.deepEqual(await(await post('delete',enrolled)).json(),{deleted:true});
});

test('preserved sections retain their original cited source metadata even when current search omits it',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();f.advance();f.change();await f.service.tick();
 f.store.commit(data=>{const report=data.monitors[enrolled.id].report;report.sources.push({url:'https://example.org/old-source',title:'Previous evidence',publishedAt:'2026-09-01'});for(const id of ['readiness','fit'])report.sections.find(s=>s.id===id).sourceURLs=['https://example.org/old-source'];});
 f.advance();f.change();f.state.scoreReason=false;await f.service.tick();const report=f.service.status(enrolled).report;
 assert.deepEqual(report.sections.find(s=>s.id==='fit').sourceURLs,['https://example.org/old-source']);assert.equal(report.sources.find(s=>s.url==='https://example.org/old-source').publishedAt,'2026-09-01');assert.ok(report.sections.find(s=>s.id==='readiness').sourceURLs.includes('https://example.org/old-source'));
});

test('editing monitored inputs during a held search discards the old job before model spend',async t=>{
 const f=fixture(t),input=body(),enrolled=await f.service.enroll(input);await f.service.tick();f.advance();f.change();let release;f.state.hold=new Promise(resolve=>{release=resolve;});
 const ticking=f.service.tick();await new Promise(resolve=>setImmediate(resolve));
 const edited=await f.service.enroll({...input,founder:{...input.founder,region:'Austin'}});const due=edited.nextCheckAt;release();await ticking;
 const record=f.store.data.monitors[edited.id],snapshot=f.service.status(edited);assert.equal(record.evidence,null);assert.equal(snapshot.report,undefined);assert.deepEqual(snapshot.events,[]);assert.equal(snapshot.nextCheckAt,due);assert.equal(snapshot.founder.region,'Austin');assert.equal(f.state.model,0);
});
test('a verified entitlement expiring during research stops before subsequent model calls',async t=>{
 const f=fixture(t),enrolled=await f.service.enroll(body());await f.service.tick();f.advance();f.change();let release;f.state.hold=new Promise(resolve=>{release=resolve;});
 const ticking=f.service.tick();await new Promise(resolve=>setImmediate(resolve));f.advance(8*DAY);release();await ticking;assert.equal(f.state.model,0);assert.equal(f.service.status(enrolled).status,'expired');
});
