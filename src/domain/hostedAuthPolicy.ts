/** Hosted DEV is invitation/operator-only until age and trust-safety release gates pass. */
export const HOSTED_DEV_PROJECT='jtrdvnwbxpfdnbzasvcj';
export type SafeAuthSettings={
  disable_signup?:unknown;
  mailer_autoconfirm?:unknown;
  external_email_enabled?:unknown;
  mailer_subjects_confirmation?:unknown;
  mailer_subjects_recovery?:unknown;
  mailer_templates_confirmation_content?:unknown;
  mailer_templates_recovery_content?:unknown;
};
export type HostedTemplates={confirmation:string;recovery:string};
export const SUBJECT_CONFIRM='my_fitness_date · Confirma tu correo';
export const SUBJECT_RECOVERY='my_fitness_date · Recupera tu contraseña';

/** A client-side UI gate, NOT server-side authorization. Hosted signup must be disabled in GoTrue. */
export function canShowQaSignup(url:unknown,flag:unknown):boolean{
  if(flag!=='LOCAL_QA_ONLY'||typeof url!=='string')return false;
  try{
    const u=new URL(url);
    return u.protocol==='http:' &&
      (u.hostname==='127.0.0.1'||u.hostname==='localhost') &&
      u.port==='54321' && (u.pathname==='/'||u.pathname==='');
  }catch{return false;}
}
export function inspectHostedAuth(
  config:SafeAuthSettings,templates:HostedTemplates
){
  const result={
    signupClosed:config.disable_signup===true,
    confirmationRequired:config.mailer_autoconfirm===false,
    emailProviderEnabled:config.external_email_enabled===true,
    confirmationTemplateMatches:config.mailer_templates_confirmation_content===templates.confirmation,
    recoveryTemplateMatches:config.mailer_templates_recovery_content===templates.recovery,
    confirmationSubjectMatches:config.mailer_subjects_confirmation===SUBJECT_CONFIRM,
    recoverySubjectMatches:config.mailer_subjects_recovery===SUBJECT_RECOVERY,
  };
  return {...result,ready:Object.values(result).every(Boolean)};
}
/** Safe, narrowly scoped PATCH payload: never include SMTP credentials or allow public signup. */
export function hostedAuthPatch(templates:HostedTemplates){
  return {
    disable_signup:true,
    mailer_autoconfirm:false,
    mailer_subjects_confirmation:SUBJECT_CONFIRM,
    mailer_subjects_recovery:SUBJECT_RECOVERY,
    mailer_templates_confirmation_content:templates.confirmation,
    mailer_templates_recovery_content:templates.recovery,
  };
}
