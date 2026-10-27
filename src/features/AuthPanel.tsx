import React,{useState} from 'react';
import {Pressable,StyleSheet,Text,TextInput,View} from 'react-native';
import {supabase} from '../lib/supabase';
import {isAdult} from '../domain/onboarding';
import {canShowQaSignup} from '../domain/hostedAuthPolicy';

type Phase='login'|'confirm'|'forgot'|'reset';
export default function AuthPanel(){
 const qaSignupAllowed=canShowQaSignup(
   process.env.EXPO_PUBLIC_SUPABASE_URL,process.env.EXPO_PUBLIC_QA_SIGNUP_FLAG,
 );
 const [phase,setPhase]=useState<Phase>('login');
 const [email,setEmail]=useState('');
 const [password,setPassword]=useState('');
 const [passwordConfirm,setPasswordConfirm]=useState('');
 const [code,setCode]=useState('');
 const [dob,setDob]=useState('');
 const [adultConfirmed,setAdultConfirmed]=useState(false);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');

 function changePhase(next:Phase){
  setPhase(next);setMessage('');setPassword('');setPasswordConfirm('');setCode('');
 }
 function goodEmail(){return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());}
 async function submit(signUp:boolean){
  if(!supabase)return;
  if(!goodEmail()||password.length<8){
   setMessage('Introduce un correo válido y una contraseña de al menos ocho caracteres.');
   return;
  }
  if(signUp&&!qaSignupAllowed){setMessage('El registro público no está habilitado.');return;}
  if(signUp&&(!adultConfirmed||!isAdult(dob))){
   setMessage('Para crear una cuenta debes declarar al menos 18 años.');
   return;
  }
  setBusy(true);setMessage('');
  try{
   const {data,error}=signUp
    ? await supabase.auth.signUp({email:email.trim().toLowerCase(),password})
    : await supabase.auth.signInWithPassword({email:email.trim().toLowerCase(),password});
   if(error)throw error;
   if(signUp&&!data.session){
    setPhase('confirm');
    setMessage('Revisa tu correo y escribe el código de confirmación.');
   }
  }catch(e){
   setMessage(e instanceof Error?e.message:'No se pudo completar la autenticación.');
  }finally{setPassword('');setBusy(false);}
 }
 async function confirmSignup(){
  if(!supabase)return;
  if(!/^\d{6,10}$/.test(code.trim())||!goodEmail()){
   setMessage('Introduce el código de correo recibido.');
   return;
  }
  setBusy(true);setMessage('');
  try{
   const {error}=await supabase.auth.verifyOtp({
    email:email.trim().toLowerCase(),token:code.trim(),type:'signup',
   });
   if(error)throw error;
   setCode('');setMessage('Correo confirmado. Sesión iniciada.');
  }catch(e){setMessage(e instanceof Error?e.message:'No se pudo confirmar el correo.');}
  finally{setBusy(false);}
 }
 async function requestRecovery(){
  if(!supabase)return;
  if(!goodEmail()){setMessage('Introduce un correo válido.');return;}
  setBusy(true);setMessage('');
  try{
   // Generic response: do not disclose whether the address exists.
   await supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
   setPhase('reset');
   setMessage('Si existe una cuenta con ese correo, recibirás instrucciones de recuperación.');
  }catch{
   setMessage('Si existe una cuenta con ese correo, revisa su bandeja; si falla, inténtalo después.');
  }finally{setBusy(false);}
 }
 async function completeRecovery(){
  if(!supabase)return;
  if(!goodEmail()||!/^\d{6,10}$/.test(code.trim())){
   setMessage('Introduce un correo válido y el código recibido.');return;
  }
  if(password.length<10||password!==passwordConfirm){
   setMessage('La nueva contraseña debe tener 10 caracteres o más y coincidir.');
   return;
  }
  setBusy(true);setMessage('');
  let temporarySession=false;
  try{
   const result=await supabase.auth.verifyOtp({
    email:email.trim().toLowerCase(),token:code.trim(),type:'recovery',
   });
   if(result.error)throw result.error;
   temporarySession=true;
   const update=await supabase.auth.updateUser({password});
   if(update.error)throw update.error;
   setPhase('login');setCode('');setPassword('');setPasswordConfirm('');
   setMessage('Contraseña actualizada. Inicia sesión de nuevo.');
  }catch(e){
   setMessage(e instanceof Error?e.message:'No fue posible restablecer la contraseña.');
  }finally{
   // Recovery verification temporarily signs in: clear local session even
   // after update failures; require an explicit password login.
   if(temporarySession)await supabase.auth.signOut({scope:'local'}).catch(()=>{});
   setBusy(false);
  }
 }
 return <View style={styles.box} testID="auth-panel">
  <Text style={styles.title}>Tu cuenta fitness</Text>
  <Text style={styles.help}>Comunidad y Actividades son independientes de las citas. La beta pública todavía no está disponible.</Text>
  <TextInput testID="auth-email" accessibilityLabel="Correo electrónico"
    style={styles.input} placeholder="Correo electrónico" placeholderTextColor="#92A3AA"
   autoCapitalize="none" autoComplete="email" keyboardType="email-address"
   value={email} onChangeText={setEmail} editable={!busy}/>
  {phase==='login'&&<>
   <TextInput testID="auth-password" accessibilityLabel="Contraseña"
    style={styles.input} placeholder="Contraseña" placeholderTextColor="#92A3AA"
    secureTextEntry value={password} onChangeText={setPassword} editable={!busy}/>
   <Pressable testID="auth-login" accessibilityRole="button" accessibilityLabel="Iniciar sesión"
    disabled={busy} style={styles.primary} onPress={()=>void submit(false)}>
    <Text style={styles.primaryText}>{busy?'Procesando…':'Entrar'}</Text>
   </Pressable>
   {qaSignupAllowed&&<>
   <Text style={styles.help}>Para crear una cuenta de desarrollo local, declara tu fecha de nacimiento (AAAA-MM-DD).</Text>
   <TextInput testID="auth-date-of-birth" accessibilityLabel="Fecha de nacimiento"
    style={styles.input} placeholder="1994-01-15" placeholderTextColor="#92A3AA"
    keyboardType="numbers-and-punctuation" value={dob} onChangeText={setDob} editable={!busy}/>
   <Pressable testID="auth-adult-consent" accessibilityRole="checkbox"
    accessibilityState={{checked:adultConfirmed}} accessibilityLabel="Confirmo que tengo al menos 18 años"
    disabled={busy} onPress={()=>setAdultConfirmed(x=>!x)} style={styles.check}>
    <Text style={styles.help}>{adultConfirmed?'☑':'☐'} Confirmo que tengo al menos 18 años.</Text>
   </Pressable>
   <Pressable testID="auth-signup" accessibilityRole="button" accessibilityLabel="Crear cuenta de desarrollo"
    disabled={busy} onPress={()=>void submit(true)} style={styles.secondary}>
    <Text style={styles.link}>Crear cuenta de desarrollo local</Text>
   </Pressable>
   </>}
   {!qaSignupAllowed&&<Text style={styles.help}>El registro está cerrado. Solo pueden ingresar cuentas de prueba autorizadas.</Text>}
   <Pressable testID="auth-forgot" accessibilityRole="button" accessibilityLabel="Olvidé mi contraseña"
    disabled={busy} onPress={()=>changePhase('forgot')} style={styles.secondary}>
    <Text style={styles.link}>Olvidé mi contraseña</Text>
   </Pressable>
   <Pressable testID="auth-have-code" accessibilityRole="button" accessibilityLabel="Ya tengo un código"
    disabled={busy} onPress={()=>changePhase('confirm')} style={styles.secondary}>
    <Text style={styles.link}>Ya tengo un código de confirmación</Text>
   </Pressable>
  </>}
  {phase==='confirm'&&<>
   <Text style={styles.help}>Escribe el código enviado al correo al registrarte.</Text>
   <TextInput style={styles.input} value={code} onChangeText={setCode}
    placeholder="Código de confirmación" placeholderTextColor="#92A3AA"
    keyboardType="number-pad" maxLength={10} editable={!busy}/>
   <Pressable testID="auth-verify-email" accessibilityRole="button" accessibilityLabel="Confirmar correo"
    disabled={busy} style={styles.primary} onPress={()=>void confirmSignup()}>
    <Text style={styles.primaryText}>{busy?'Verificando…':'Confirmar correo'}</Text>
   </Pressable>
  </>}
  {phase==='forgot'&&<>
   <Text style={styles.help}>Te enviaremos un código al correo si existe una cuenta asociada.</Text>
   <Pressable testID="auth-request-recovery" accessibilityRole="button"
    accessibilityLabel="Solicitar recuperación de contraseña"
    disabled={busy} style={styles.primary} onPress={()=>void requestRecovery()}>
    <Text style={styles.primaryText}>Solicitar recuperación</Text>
   </Pressable>
  </>}
  {phase==='reset'&&<>
   <Text style={styles.help}>Introduce el código recibido y una nueva contraseña.</Text>
   <TextInput style={styles.input} placeholder="Código de recuperación"
    placeholderTextColor="#92A3AA" keyboardType="number-pad"
    maxLength={10} value={code} onChangeText={setCode} editable={!busy}/>
   <TextInput style={styles.input} placeholder="Nueva contraseña (10 caracteres mínimo)"
    placeholderTextColor="#92A3AA" secureTextEntry value={password}
    onChangeText={setPassword} editable={!busy}/>
   <TextInput style={styles.input} placeholder="Confirmar nueva contraseña"
    placeholderTextColor="#92A3AA" secureTextEntry value={passwordConfirm}
    onChangeText={setPasswordConfirm} editable={!busy}/>
   <Pressable testID="auth-complete-recovery" accessibilityRole="button"
    accessibilityLabel="Guardar nueva contraseña"
    disabled={busy} style={styles.primary} onPress={()=>void completeRecovery()}>
    <Text style={styles.primaryText}>{busy?'Actualizando…':'Cambiar contraseña'}</Text>
   </Pressable>
  </>}
  {phase!=='login'&&<Pressable disabled={busy} style={styles.secondary}
    onPress={()=>changePhase('login')}><Text style={styles.link}>Volver a entrar</Text></Pressable>}
  {message?<Text style={styles.message}>{message}</Text>:null}
  <Text style={styles.warning}>Solo desarrollo: la edad es autodeclarada, falta verificación de identidad y moderación operativa. No usar con personas reales.</Text>
 </View>;
}
const styles=StyleSheet.create({
 box:{backgroundColor:'#16262D',padding:18,borderRadius:16},
 title:{fontSize:20,fontWeight:'800',color:'#F6FAFA',marginBottom:10},
 help:{color:'#B8CACF',fontSize:13,lineHeight:20,marginVertical:5},
 input:{borderColor:'#435860',borderWidth:1,padding:12,marginVertical:6,
  borderRadius:10,color:'#F6FAFA',backgroundColor:'#0C1920'},
 check:{paddingVertical:6},
 primary:{backgroundColor:'#B6F266',padding:14,borderRadius:12,alignItems:'center',marginTop:10},
 primaryText:{fontWeight:'900',color:'#142014'},
 secondary:{alignItems:'center',padding:10},
 link:{color:'#B6F266',fontWeight:'700',fontSize:12},
 message:{color:'#FFE3A8',fontSize:13,marginTop:8},
 warning:{color:'#8EA4AD',fontSize:11,lineHeight:17,marginTop:8},
});
