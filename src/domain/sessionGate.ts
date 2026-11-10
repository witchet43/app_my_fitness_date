export type AccountGate =
  | { state:'idle' }
  | { state:'checking'; userId:string }
  | { state:'allowed'; userId:string; pending:boolean }
  | { state:'error'; userId:string; reason:string };

export function readPendingFlag(data:unknown):boolean {
  if (data===null || typeof data!=='object' || Array.isArray(data) ||
      typeof (data as Record<string,unknown>).pending!=='boolean') {
    throw new Error('La respuesta de privacidad no pudo validarse.');
  }
  return (data as {pending:boolean}).pending;
}
export function isVerified(gate:AccountGate,uid:string|null):boolean {
  return Boolean(uid && gate.state==='allowed' && gate.userId===uid);
}
export function mayEnter(gate:AccountGate,uid:string|null,section:'account'|'social'|'admin'):boolean {
  return isVerified(gate,uid) &&
   (section==='account'||(gate.state==='allowed' && !gate.pending));
}
