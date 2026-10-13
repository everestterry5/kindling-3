import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createServer } from '../server.mjs';
import { FreeUsageStore } from '../usage.mjs';
import { SECTION_IDS, validateAnalysis, normalizeAnalysis, buildAnalysisRequest } from '../analysis.mjs';
const body = { clientId: 'analysis-test-install', consent: true, idea: { title: 'Community garden', summary: 'Shared neighborhood plots with weekly classes', customer: 'Apartment residents', problem: 'No space', businessModel: 'Monthly membership', category: 'Local service' }, founder: { budget: '$1000 USD', hours: '5 weekly', skills: 'Gardening', experience: '2 years', distribution: '20 neighbors', region: 'Chicago' } };
const raw = () => ({ sections: SECTION_IDS.map(id => ({ id, headline: `Assessment of ${id}`, score: ['entry','fit','readiness'].includes(id) ? 60 : null, confidence: 'medium', body: `Specific analysis for ${id}.`, actions: ['Interview 5 customers'], unknowns: ['Willingness to pay'], sourceURLs: [] })) });
const research = { status: 'available', sources: [{ url: 'https://example.org/research', title: 'Research', excerpt: 'Dated evidence', publishedAt: '2026-10-01' }] };
test('analysis requires explicit consent and bounded founder inputs', () => {
 assert.equal(validateAnalysis(body), null);
 assert.match(validateAnalysis({ ...body, consent: false }), /consent/);
 assert.match(validateAnalysis({ ...body, founder: { ...body.founder, skills: 'x'.repeat(1001) } }), /skills/);
 assert.match(validateAnalysis({ ...body, isPro: true }), /signed transaction/);
});
test('all sections required, duplicate sections and invalid scores rejected', () => {
 const missing=raw(); missing.sections.pop(); assert.throws(()=>normalizeAnalysis(missing,research,body));
 const duplicate=raw(); duplicate.sections[1]=duplicate.sections[0]; assert.throws(()=>normalizeAnalysis(duplicate,research,body));
 const invalid=raw(); invalid.sections[0].score=101; assert.throws(()=>normalizeAnalysis(invalid,research,body));
});
test('invented citations never turn market placeholders into facts', () => {
 const data=raw(); data.sections.find(s=>s.id==='momentum').sourceURLs=['https://invented.example/trend','javascript:alert(1)'];
 const result=normalizeAnalysis(data,research,body);
 assert.equal(result.sections.find(s=>s.id==='momentum').headline,'More research needed');
 assert.equal(result.sections.find(s=>s.id==='competitors').score,null);
 assert.ok(!JSON.stringify(result).includes('invented.example'));
});
test('real citations survive with source dates; incomplete profile never gets a fit number', () => {
 const data=raw(); data.sections.find(s=>s.id==='competitors').sourceURLs=[research.sources[0].url];
 const result=normalizeAnalysis(data,research,{...body,founder:{...body.founder,skills:''}});
 assert.equal(result.sections.find(s=>s.id==='fit').score,null);
 assert.deepEqual(result.sections.find(s=>s.id==='competitors').sourceURLs,[research.sources[0].url]);
 assert.equal(result.sources[0].publishedAt,'2026-10-01'); assert.equal(result.sources[0].excerpt,undefined);
});
test('provider request excludes purchase and installation identity and legacy scores',()=>{
 const request=JSON.stringify(buildAnalysisRequest({...body,signedTransaction:'private-proof',idea:{...body.idea,viabilityScore:99}},research,'test-model'));
 assert.ok(!request.includes('private-proof')); assert.ok(!request.includes(body.clientId)); assert.ok(!request.includes('viabilityScore'));
});
async function start(t, fetchImpl, env={}) {
 const dir=mkdtempSync(join(tmpdir(),'kindling-analysis-')); const usage=new FreeUsageStore(join(dir,'quota.json'));
 const server=createServer({env:{DEEPSEEK_API_KEY:'offline-test',DEEPSEEK_MODEL:'offline-model',...env},usage,apple:{ready:false,verify:async()=>{throw Object.assign(new Error('Invalid subscription.'),{status:401});}},fetchImpl,logger:{error(){}}});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 t.after(async()=>{await new Promise(resolve=>server.close(resolve));rmSync(dir,{recursive:true,force:true});});
 return {usage,post:(value=body)=>fetch(`http://127.0.0.1:${server.address().port}/v1/ideas/analyze`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(value)})};
}
const good = () => ({ok:true,json:async()=>({choices:[{finish_reason:'stop',message:{content:JSON.stringify(raw())}}]})});
test('HTTP DeepSeek analysis fills all tabs and enforces shared free quota',async t=>{
 let calls=0;const {post}=await start(t,async(url,options)=>{calls++;assert.equal(url,'https://api.deepseek.com/chat/completions');assert.equal(JSON.parse(options.body).response_format.type,'json_object');return good();});
 for(let i=0;i<3;i++){const r=await post();assert.equal(r.status,200);assert.equal((await r.json()).sections.length,13);}
 assert.equal((await post()).status,402);assert.equal(calls,3);
});
test('truncated or malformed provider responses refund quota and expose no internals',async t=>{
 const {post}=await start(t,async()=>({ok:true,json:async()=>({choices:[{finish_reason:'length',message:{content:'secret'}}]})}));
 for(let i=0;i<4;i++){const r=await post();assert.equal(r.status,502);assert.ok(!(await r.text()).includes('secret'));}
});
test('search failure returns honest partial report; private founder details never enter search',async t=>{
 const {post}=await start(t,async(url,options)=>{
 if(url.includes('tavily')){const q=JSON.parse(options.body).query;assert.ok(!q.includes(body.founder.budget));assert.ok(!q.includes(body.founder.experience));throw new Error('offline');}
 return good();
 },{TAVILY_API_KEY:'offline-search'});
 const result=await (await post()).json();assert.equal(result.researchStatus,'unavailable');assert.equal(result.sections.find(s=>s.id==='momentum').score,null);
});
test('invalid entitlement and absent consent cannot reach the provider',async t=>{
 let calls=0;const {post}=await start(t,async()=>{calls++;return good();});
 assert.equal((await post({...body,consent:false})).status,400);
 assert.equal((await post({...body,signedTransaction:'forged'})).status,401);assert.equal(calls,0);
});
test('DeepSeek chat uses the configured model and filters invented citations', async()=>{
 const { generateDeepSeekChat }=await import('../analysis.mjs');
 const result=await generateDeepSeekChat({...body,messages:[{role:'user',content:'What next?'}]}, {DEEPSEEK_MODEL:'test-model',DEEPSEEK_API_KEY:'offline'},async(url,options)=>{
 assert.equal(JSON.parse(options.body).model,'test-model');
 return {ok:true,json:async()=>({choices:[{finish_reason:'stop',message:{content:JSON.stringify({text:'Test the offer.',insight:'Demand is unknown.',action:'Interview five customers.',signal:'action',sourceURLs:['https://invented.example']})}}]})};
 });
 assert.deepEqual(result.sources,[]);assert.equal(result.signal,'action');
});
