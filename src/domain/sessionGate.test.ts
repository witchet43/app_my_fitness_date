import assert from 'node:assert/strict';
import test from 'node:test';
import {isVerified,mayEnter,readPendingFlag,type AccountGate} from './sessionGate';

test('gate denies access before account status verification',()=>{
  const states:AccountGate[]=[{state:'idle'},{state:'checking',userId:'a'},
    {state:'error',userId:'a',reason:'Network error'}];
  for(const state of states) {
    assert.equal(isVerified(state,'a'),false);
    assert.equal(mayEnter(state,'a','social'),false);
    assert.equal(mayEnter(state,'a','account'),false);
  }
});
test('gate is scoped to the actual session identity',()=>{
  const state:AccountGate={state:'allowed',userId:'account-a',pending:false};
  assert.equal(mayEnter(state,'account-a','social'),true);
  assert.equal(mayEnter(state,'account-b','social'),false);
  assert.equal(mayEnter(state,null,'account'),false);
});
test('pending deletion only permits account controls',()=>{
  const state:AccountGate={state:'allowed',userId:'a',pending:true};
  assert.equal(mayEnter(state,'a','account'),true);
  assert.equal(mayEnter(state,'a','social'),false);
  assert.equal(mayEnter(state,'a','admin'),false);
});
test('only strictly valid privacy RPC replies grant access',()=>{
  assert.equal(readPendingFlag({pending:false}),false);
  assert.equal(readPendingFlag({pending:true,requested_at:'2026-10-27'}),true);
  for(const value of [null,undefined,false,{},[],{pending:'false'}, {pending:null}]) {
    assert.throws(()=>readPendingFlag(value),/respuesta de privacidad/);
  }
});
