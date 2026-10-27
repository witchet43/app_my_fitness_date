import React, { useEffect, useMemo, useState } from 'react';
import { AppState, KeyboardAvoidingView, Platform, Pressable, SafeAreaView, ScrollView, StatusBar, StyleSheet, Text, View } from 'react-native';
import type { Session } from '@supabase/supabase-js';
import AuthPanel from './src/features/AuthPanel';
import LiveCommunity from './src/features/LiveCommunity';
import LiveTogether from './src/features/LiveTogether';
import LiveDating from './src/features/LiveDating';
import AdminModeration from './src/features/AdminModeration';
import ModerationInbox from './src/features/ModerationInbox';
import AccountCenter from './src/features/AccountCenter';
import { supabase, supabaseIsConfigured } from './src/lib/supabase';
import { currentUser, demoActivities, demoCandidates, demoPosts } from './src/demo/fixtures';
import { isEligibleForDating, type GymShieldMode } from './src/domain/gymShield';
import { isVerified, mayEnter, readPendingFlag, type AccountGate } from './src/domain/sessionGate';
import { BASE_TABS, tabsForAccount, type MobileTab as Tab } from './src/domain/mobileNavigation';

const TABS=BASE_TABS;

export default function App() {
  const [tab, setTab] = useState<Tab>('community');
  const [mode, setMode] = useState<GymShieldMode>('other_gyms');
  const [session, setSession] = useState<Session | null>(null);
  const [authReady, setAuthReady] = useState(!supabaseIsConfigured);
  const [authError, setAuthError] = useState('');
  const [moderator, setModerator] = useState(false);
  const [accountGate,setAccountGate]=useState<AccountGate>({state:'idle'});
  const [gateVersion,setGateVersion]=useState(0);

  useEffect(() => {
    if (!supabase) return;
    const client = supabase;
    let active = true;
    void client.auth.getSession().then(({data,error}) => {
      if (!active) return;
      if (error) setAuthError(error.message);
      setSession(data.session);
      setAuthReady(true);
    }).catch((error:unknown) => {
      if (!active) return;
      setAuthError(error instanceof Error ? error.message : 'Error al obtener sesión');
      setAuthReady(true);
    });
    const listener=client.auth.onAuthStateChange((_event,next)=>{
      if (active) {
        setSession(next);
        setAuthReady(true);
      }
    });
    return ()=>{active=false;listener.data.subscription.unsubscribe();};
  },[]);

  useEffect(() => {
    setModerator(false);
    if (!session || !supabase) return;
    const client = supabase;
    let active = true;
    void (async () => {
      try {
        const { data, error } = await client.rpc('is_moderator');
        if (active) {
          if (error) setAuthError(error.message);
          setModerator(!error && data === true);
        }
      } catch (error: unknown) {
        if (active) setAuthError(error instanceof Error ? error.message : 'Error al verificar permisos');
      }
    })();
    return () => { active = false; };
  }, [session?.user.id,gateVersion]);

  // Fail closed. Account status is authenticated on every session change or
  // foreground resumption. Never render private tabs until the request succeeds.
  useEffect(()=>{
    if (!session || !supabase) {
      setAccountGate({state:'idle'});
      return;
    }
    const uid=session.user.id;
    const client=supabase;
    let active=true;
    setAccountGate({state:'checking',userId:uid});
    setTab('community');
    void (async()=>{
      try {
        const {data,error}=await client.rpc('my_account_status');
        if(error)throw error;
        const pending=readPendingFlag(data);
        if(active){
          setAccountGate({state:'allowed',userId:uid,pending});
          if(pending)setTab('account');
        }
      }catch(e){
        if(active)setAccountGate({
          state:'error',userId:uid,
          reason:e instanceof Error?e.message:'No se pudo validar tu cuenta',
        });
      }
    })();
    return ()=>{active=false;};
  },[session?.user.id,gateVersion]);

  useEffect(()=>{
    if(!supabase)return;
    const sub=AppState.addEventListener('change',state=>{
      if(state==='active')setGateVersion(version=>version+1);
    });
    return ()=>sub.remove();
  },[]);

  const uid=session?.user.id||null;
  const verified=isVerified(accountGate,uid);
  const deletionPending=verified && accountGate.state==='allowed' && accountGate.pending;
  const allowedContent=mayEnter(accountGate,uid,'social');

  const visibleTabs=tabsForAccount({
    authenticated:Boolean(session),verified,deletionPending,moderator,
  });

  const matches = useMemo(() =>
    demoCandidates.filter(candidate=>isEligibleForDating({...currentUser,mode},candidate)),[mode]);

  return <SafeAreaView style={s.safe}>
    <StatusBar barStyle="light-content" />
    <View style={s.header}>
      <Text style={s.kicker}>TRAIN · CONNECT · BELONG</Text>
      <Text style={s.brand}>my_fitness_<Text style={s.accent}>date</Text></Text>
      <Text style={s.subtitle}>La comunidad y las citas son espacios independientes.</Text>
      {session && <Pressable testID="header-signout" accessibilityRole="button"
        accessibilityLabel="Cerrar sesión de my fitness date"
        onPress={()=>void supabase?.auth.signOut()} style={s.signout}>
        <Text style={s.signoutText}>Cerrar sesión</Text>
      </Pressable>}
    </View>
    <ScrollView horizontal showsHorizontalScrollIndicator={false}
      style={s.tabs} contentContainerStyle={s.tabsContent}
      keyboardShouldPersistTaps="handled" accessibilityLabel="Secciones de la aplicación">
      {visibleTabs.map(item=><Pressable key={item.id} testID={'tab-'+item.id}
        accessibilityLabel={item.title} accessibilityHint={'Abrir sección '+item.title}
        accessibilityRole="tab" accessibilityState={{selected:tab===item.id}}
        onPress={()=>setTab(item.id)}
        style={[s.tab,tab===item.id&&s.tabActive]}>
        <Text style={[s.tabText,tab===item.id&&s.tabTextActive]}>
          {item.emoji} {item.title}
        </Text>
      </Pressable>)}
    </ScrollView>
    <KeyboardAvoidingView style={s.main} behavior={Platform.OS==='ios'?'padding':undefined}>
    <ScrollView testID="main-scroll" contentContainerStyle={s.content}
      keyboardDismissMode="on-drag" keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}>
      <View style={s.notice}><Text style={s.noticeText}>DESARROLLO · Sin usuarios reales · Acceso controlado pendiente</Text></View>
      {tab==='admin' && !moderator && <Text style={s.warning}>Acceso administrativo no autorizado.</Text>}
      {deletionPending && tab!=='account' && <Text style={s.warning}>La solicitud de baja está pendiente. Abre Cuenta para revisarla o cancelarla.</Text>}
      {supabaseIsConfigured ? (
        !authReady ? <Text style={s.lead}>Comprobando sesión...</Text> :
        session ? !verified ? <View style={s.gate} testID="access-check">
          <Text style={s.sectionTitle}>Validando acceso</Text>
          {accountGate.state==='error' ?
            <Text style={s.warning}>{accountGate.reason}</Text> :
            <Text style={s.lead}>Comprobando permisos y privacidad de tu cuenta…</Text>}
          <Pressable testID="access-retry" accessibilityRole="button"
            accessibilityLabel="Reintentar verificación de cuenta"
            style={s.option} onPress={()=>setGateVersion(v=>v+1)}>
            <Text style={s.body}>Reintentar verificación</Text>
          </Pressable>
          <Pressable testID="access-signout" accessibilityRole="button"
            accessibilityLabel="Salir de la cuenta"
            style={s.option} onPress={()=>void supabase?.auth.signOut()}>
            <Text style={s.body}>Cerrar sesión</Text>
          </Pressable>
        </View> : <View testID={'screen-'+tab} key={session.user.id + tab}>
          {tab==='community' && allowedContent && <LiveCommunity session={session}/>}
          {tab==='together' && allowedContent && <LiveTogether session={session}/>}
          {tab==='dating' && allowedContent && <LiveDating session={session}/>}
          {tab==='inbox' && allowedContent && <ModerationInbox session={session}/>}
          {tab==='admin' && moderator && allowedContent && <AdminModeration session={session}/>}
          {tab==='account' && <AccountCenter session={session}
            onStatusChange={pending=>{
              setAccountGate({state:'allowed',userId:session.user.id,pending});
              if(pending)setTab('account');
            }}/>}
        </View> : <AuthPanel/>
      ) : <>
        <Text style={s.lead}>Demostración local con datos ficticios. Configura Supabase para activar las funciones sociales.</Text>
        {tab==='community' && <>
          <Text style={s.sectionTitle}>Tu gente se mueve</Text>
          {demoPosts.map(post=><View style={s.card} key={post.author}>
            <Text style={s.tag}>{post.sport}</Text>
            <Text style={s.cardTitle}>{post.author}</Text>
            <Text style={s.body}>{post.body}</Text>
          </View>)}
        </>}
        {tab==='together' && <>
          <Text style={s.sectionTitle}>Entrena acompañado</Text>
          {demoActivities.map(activity=><View style={s.card} key={activity.title}>
            <Text style={s.tag}>{activity.sport}</Text>
            <Text style={s.cardTitle}>{activity.title}</Text>
            <Text style={s.body}>{activity.detail}</Text>
          </View>)}
        </>}
        {tab==='dating' && <>
          <Text style={s.sectionTitle}>Gym Shield</Text>
          <Pressable style={[s.option,mode==='other_gyms'&&s.optionActive]} onPress={()=>setMode('other_gyms')}>
            <Text style={s.body}>Solo otros gimnasios</Text>
          </Pressable>
          <Pressable style={[s.option,mode==='same_gym_other_time'&&s.optionActive]} onPress={()=>setMode('same_gym_other_time')}>
            <Text style={s.body}>Mismo gym, otro horario</Text>
          </Pressable>
          <Text style={s.sectionTitle}>Perfiles ficticios: {matches.length}</Text>
          {matches.map(candidate=><View style={s.card} key={candidate.id}>
            <Text style={s.cardTitle}>{candidate.displayName}</Text>
            <Text style={s.body}>{candidate.sports} · {candidate.city}</Text>
          </View>)}
        </>}
      </>}
      {authError?<Text style={s.warning}>{authError}</Text>:null}
    </ScrollView>
    </KeyboardAvoidingView>
    <View style={s.footer}><Text style={s.footerText}>PROTOTIPO TÉCNICO · v0.18.0</Text></View>
  </SafeAreaView>;
}

const s=StyleSheet.create({
 safe:{flex:1,backgroundColor:'#091319'},
 main:{flex:1},
 header:{paddingHorizontal:20,paddingTop:17,paddingBottom:14},
 kicker:{fontSize:10,letterSpacing:2,color:'#9EB2BC',fontWeight:'700'},
 brand:{fontSize:28,fontWeight:'800',letterSpacing:-0.8,color:'#F8FAFA',marginTop:4},
 accent:{color:'#B6F266'},
 subtitle:{marginTop:5,color:'#B6C6CB',fontSize:12},
 signout:{marginTop:9,alignSelf:'flex-start',minHeight:44,justifyContent:'center'},
 signoutText:{color:'#B6F266',fontSize:12,fontWeight:'700'},
 tabs:{marginHorizontal:16,backgroundColor:'#15252C',borderRadius:14,maxHeight:52},
 tabsContent:{flexDirection:'row',padding:4,alignItems:'center'},
 tab:{minWidth:106,minHeight:44,paddingHorizontal:12,paddingVertical:12,alignItems:'center',justifyContent:'center',borderRadius:11},
 tabActive:{backgroundColor:'#B6F266'},
 tabText:{color:'#BECBD0',fontWeight:'700',fontSize:11},
 tabTextActive:{color:'#101C20'},
 content:{padding:19,paddingBottom:32},
 notice:{backgroundColor:'#26302C',padding:10,borderRadius:10,marginBottom:15},
 noticeText:{color:'#D5F9A1',fontSize:10,fontWeight:'800'},
 sectionTitle:{color:'#F7FAFA',fontWeight:'800',fontSize:21,marginVertical:8},
 lead:{color:'#B8C6CC',fontSize:13,lineHeight:20,marginBottom:14},
 card:{padding:16,backgroundColor:'#16262D',borderRadius:14,marginBottom:12,borderWidth:1,borderColor:'#263B43'},
 tag:{color:'#B6F266',fontWeight:'800',fontSize:11,marginBottom:8},
 cardTitle:{color:'#F3F7F8',fontSize:17,fontWeight:'800',marginBottom:7},
 body:{color:'#C4D0D5',fontSize:13,lineHeight:20},
 option:{minHeight:44,padding:14,borderRadius:11,marginVertical:6,borderWidth:1,borderColor:'#43525A'},
 optionActive:{borderColor:'#B6F266',backgroundColor:'#283B2B'},
 gate:{padding:14,borderRadius:12,backgroundColor:'#16262D'},
 footer:{paddingVertical:10,alignItems:'center',borderTopWidth:1,borderTopColor:'#1A3038'},
 footerText:{color:'#718B94',fontWeight:'800',fontSize:10,letterSpacing:1},
 warning:{color:'#FFC9A0',fontSize:12},
});
