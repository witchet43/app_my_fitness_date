import React, { useCallback, useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import ReportPicker,{type ReportReason} from './ReportPicker';

type SocialProfile = { user_id:string; display_name:string; city:string; sports:string[] };
type Post = {
  id:string; author_id:string; body:string; sport:string; created_at:string;
  social_profiles: { display_name:string } | null;
};

export default function LiveCommunity({ session }:{ session:Session }) {
  const [profile, setProfile] = useState<SocialProfile | null>(null);
  const [displayName, setDisplayName] = useState('');
  const [city, setCity] = useState('Querétaro');
  const [sports, setSports] = useState('Running, Pesas');
  const [posts, setPosts] = useState<Post[]>([]);
  const [sport, setSport] = useState('Running');
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [reportId,setReportId]=useState<string|null>(null);
  const [notice,setNotice]=useState('');

  const load = useCallback(async () => {
    if (!supabase) return;
    const [myProfile, feed] = await Promise.all([
      supabase.from('social_profiles').select('user_id,display_name,city,sports')
        .eq('user_id', session.user.id).maybeSingle(),
      supabase.from('community_posts')
        .select('id,author_id,body,sport,created_at,social_profiles!community_posts_author_id_fkey(display_name)')
        .order('created_at', { ascending: false }).limit(30),
    ]);
    if (myProfile.error) throw myProfile.error;
    if (feed.error) throw feed.error;
    const me = (myProfile.data || null) as SocialProfile | null;
    setProfile(me);
    if (me) {
      setDisplayName(me.display_name);
      setCity(me.city);
      setSports(me.sports.join(', '));
    }
    setPosts((feed.data || []) as unknown as Post[]);
  }, [session.user.id]);

  useEffect(() => {
    let active = true;
    async function initialize() {
      try {
        // Component is keyed by signed-in user at the App level.
        if (active) await load();
      } catch (e) {
        if (active) setError(errorText(e));
      }
    }
    void initialize();
    return () => { active = false; };
  }, [load]);

  async function saveProfile() {
    if (!supabase) return;
    if (displayName.trim().length < 2 || city.trim().length < 2) {
      setError('Completa tu nombre público y ciudad.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const common = {
        display_name:displayName.trim(), city:city.trim(),
        sports:sports.split(',').map(value=>value.trim()).filter(Boolean),
      };
      const result = profile
        ? await supabase.from('social_profiles').update(common).eq('user_id',session.user.id)
        : await supabase.from('social_profiles').insert({user_id:session.user.id,...common});
      if (result.error) throw result.error;
      await load();
    } catch (e) {
      setError(errorText(e));
    } finally {setBusy(false);}
  }

  async function publish() {
    if (!supabase || !profile) return;
    if (body.trim().length < 4 || body.trim().length > 500 || sport.trim().length < 2) {
      setError('Publicación: entre 4 y 500 caracteres; agrega un deporte.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const { error: insertError } = await supabase.from('community_posts')
        .insert({author_id:session.user.id, sport:sport.trim(), body:body.trim()});
      if (insertError) throw insertError;
      setBody('');
      await load();
    } catch (e) {setError(errorText(e));} finally {setBusy(false);}
  }

  async function removePost(postId:string) {
    if (!supabase) return;
    setBusy(true);
    try {
      const { error: deleteError } = await supabase.from('community_posts')
        .delete().eq('id',postId).eq('author_id',session.user.id);
      if (deleteError) throw deleteError;
      await load();
    } catch (e) {setError(errorText(e));} finally {setBusy(false);}
  }

  async function submitReport(postId:string,reason:ReportReason){
    if(!supabase)return;
    setBusy(true);setError('');setNotice('');
    try {
      const {error}=await supabase.rpc('submit_safety_report',{
        p_target_type:'post',p_target_id:postId,p_reason:reason,p_details:null,
      });
      if(error)throw error;
      setReportId(null);setNotice('Reporte recibido para revisión.');
    }catch(error){setError(errorText(error));}finally{setBusy(false);}
  }
  async function blockAuthor(authorId:string){
    if(!supabase||authorId===session.user.id)return;
    setBusy(true);setError('');setNotice('');
    try {
      const {error}=await supabase.rpc('block_user',{p_blocked_user_id:authorId});
      if(error)throw error;
      await load();
      setReportId(null);setNotice('Cuenta bloqueada.');
    }catch(error){setError(errorText(error));}finally{setBusy(false);}
  }

  return <View testID="community-view">
    <Text style={s.title}>Fitness Community</Text>
    <Text style={s.hint}>Tu perfil social es independiente de FitDating. No se comparten gimnasios, horarios ni preferencias románticas.</Text>
    <View style={s.card}>
      <Text style={s.heading}>{profile?'Editar perfil deportivo':'Crear perfil deportivo'}</Text>
      <TextInput testID="community-name" accessibilityLabel="Nombre público"
        style={s.field} value={displayName} onChangeText={setDisplayName} placeholder="Nombre público" placeholderTextColor="#839AA2"/>
      <TextInput style={s.field} value={city} onChangeText={setCity} placeholder="Ciudad" placeholderTextColor="#839AA2"/>
      <TextInput style={s.field} value={sports} onChangeText={setSports} placeholder="Deportes separados por coma" placeholderTextColor="#839AA2"/>
      <Pressable style={s.button} disabled={busy} onPress={() => void saveProfile()}>
        <Text style={s.buttonText}>Guardar perfil social</Text>
      </Pressable>
    </View>
    {profile && <View style={s.card}>
      <Text style={s.heading}>Comparte tu entrenamiento</Text>
      <TextInput style={s.field} value={sport} onChangeText={setSport}
        placeholder="Disciplina" placeholderTextColor="#839AA2"/>
      <TextInput testID="community-post-body" accessibilityLabel="Contenido de publicación" multiline style={[s.field,s.textarea]} value={body} maxLength={500}
        onChangeText={setBody} placeholder="¿Qué hiciste hoy?" placeholderTextColor="#839AA2"/>
      <Text style={s.hint}>{body.length}/500 caracteres</Text>
      <Pressable testID="community-publish" accessibilityRole="button" accessibilityLabel="Publicar en comunidad"
        style={s.button} disabled={busy} onPress={() => void publish()}>
        <Text style={s.buttonText}>Publicar</Text>
      </Pressable>
    </View>}
    {error ? <Text style={s.error}>{error}</Text> : null}
    {notice ? <Text style={s.success}>{notice}</Text> : null}
    <View style={s.header}><Text style={s.heading}>Publicaciones recientes</Text>
      <Pressable onPress={() => void load().catch(e=>setError(errorText(e)))}>
        <Text style={s.link}>Actualizar</Text>
      </Pressable>
    </View>
    {posts.length===0 && <Text style={s.hint}>Todavía no hay publicaciones de prueba.</Text>}
    {posts.map(post=><View style={s.card} key={post.id}>
      <Text style={s.sport}>{post.sport.toUpperCase()}</Text>
      <Text style={s.heading}>{post.social_profiles?.display_name || 'Atleta'}</Text>
      <Text style={s.content}>{post.body}</Text>
      {post.author_id===session.user.id ? <Pressable disabled={busy} onPress={() => void removePost(post.id)}>
        <Text style={s.delete}>Eliminar mi publicación</Text>
      </Pressable> : <>
        <View style={s.actions}>
          <Pressable disabled={busy} onPress={()=>setReportId(post.id)}><Text style={s.delete}>Reportar</Text></Pressable>
          <Pressable disabled={busy} onPress={()=>void blockAuthor(post.author_id)}><Text style={s.delete}>Bloquear autor</Text></Pressable>
        </View>
        {reportId===post.id && <ReportPicker busy={busy} onSubmit={reason=>void submitReport(post.id,reason)}
          onCancel={()=>setReportId(null)}/>}
      </>}
    </View>)}
    <Text style={s.warning}>Entorno de desarrollo. No compartir datos personales, ubicaciones precisas ni fotografías de terceros.</Text>
  </View>;
}
function errorText(e:unknown){return e instanceof Error?e.message:'Ocurrió un error al guardar datos';}
const s=StyleSheet.create({
  title:{fontSize:23,fontWeight:'900',color:'#F7FAFA',marginBottom:7},
  hint:{fontSize:12,color:'#A3B6BF',lineHeight:18,marginBottom:8},
  heading:{fontSize:17,fontWeight:'800',color:'#F5F9FA',marginBottom:6},
  card:{backgroundColor:'#16262D',borderColor:'#28414B',borderWidth:1,
    padding:15,borderRadius:14,marginVertical:7},
  field:{backgroundColor:'#0C1A20',borderColor:'#3C5059',borderWidth:1,
    padding:11,borderRadius:10,marginVertical:5,color:'#FFFFFF'},
  textarea:{minHeight:75,textAlignVertical:'top'},
  button:{backgroundColor:'#B6F266',padding:13,borderRadius:10,alignItems:'center',marginTop:7},
  buttonText:{color:'#142014',fontWeight:'800'},
  sport:{color:'#B6F266',fontSize:11,fontWeight:'800',marginBottom:5},
  content:{color:'#D2DEE1',fontSize:14,lineHeight:20},
  header:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',marginTop:12},
  link:{color:'#B6F266',fontSize:12,fontWeight:'800'},
  error:{color:'#FFD1AB',fontSize:12,marginVertical:9},
  delete:{color:'#FFBEBC',marginTop:13,fontSize:12},
  actions:{flexDirection:'row',gap:20,marginTop:8},
  success:{color:'#C5F3AF',fontSize:12,marginTop:8},
  warning:{color:'#8299A3',marginVertical:10,fontSize:11,lineHeight:17},
});
