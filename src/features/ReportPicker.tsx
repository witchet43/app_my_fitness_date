import React from 'react';
import { Pressable,StyleSheet,Text,View } from 'react-native';
export type ReportReason = 'spam'|'harassment'|'unsafe'|'other';
const choices: Array<{value:ReportReason;label:string}>=[
 {value:'spam',label:'Spam o contenido engañoso'},
 {value:'harassment',label:'Acoso'},
 {value:'unsafe',label:'Situación insegura'},
 {value:'other',label:'Otro problema'},
];
export default function ReportPicker({busy,onSubmit,onCancel}:{busy:boolean;onSubmit:(reason:ReportReason)=>void;onCancel:()=>void}){
 return <View style={styles.box}>
  <Text style={styles.title}>Motivo del reporte</Text>
  {choices.map(choice=><Pressable disabled={busy} key={choice.value} style={styles.item}
     onPress={()=>onSubmit(choice.value)}><Text style={styles.label}>{choice.label}</Text></Pressable>)}
  <Pressable disabled={busy} onPress={onCancel} style={styles.item}>
    <Text style={styles.cancel}>Cancelar</Text>
  </Pressable>
 </View>;
}
const styles=StyleSheet.create({
 box:{backgroundColor:'#26373E',padding:12,borderRadius:10,marginTop:10},
 title:{color:'#FFFFFF',fontWeight:'800',fontSize:13},
 item:{padding:11,borderBottomWidth:1,borderBottomColor:'#435862'},
 label:{color:'#E0E8E9',fontSize:12},
 cancel:{color:'#FFC5C0',fontSize:12},
});