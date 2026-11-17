import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Whitelisted, legitimate open-licensed family names from Google Fonts.
/// The editor loads only visible previews; no 100+ font requests on open.
/// Existing four classic families remain valid for rollback compatibility.
abstract final class FittedFontCatalog {
  static const legacy=<String>['Arial','Georgia','Palatino','Garamond'];
  static const candidates=<String>[
    'Roboto',
    'Roboto Condensed',
    'Roboto Slab',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Inter',
    'Nunito',
    'Nunito Sans',
    'Raleway',
    'Oswald',
    'Ubuntu',
    'Work Sans',
    'DM Sans',
    'DM Serif Display',
    'DM Serif Text',
    'Manrope',
    'Outfit',
    'Urbanist',
    'Rubik',
    'Mulish',
    'Quicksand',
    'Karla',
    'Asap',
    'Assistant',
    'Archivo',
    'Archivo Black',
    'Barlow',
    'Barlow Condensed',
    'Barlow Semi Condensed',
    'Bebas Neue',
    'Cabin',
    'Catamaran',
    'Chivo',
    'Comfortaa',
    'Commissioner',
    'Cormorant',
    'Cormorant Garamond',
    'Crimson Text',
    'Dosis',
    'Exo',
    'Exo 2',
    'Fira Sans',
    'Fira Sans Condensed',
    'Fira Mono',
    'Fraunces',
    'Gabarito',
    'Geist',
    'Geist Mono',
    'Heebo',
    'Hind',
    'IBM Plex Sans',
    'IBM Plex Serif',
    'IBM Plex Mono',
    'Inconsolata',
    'Inria Sans',
    'Inria Serif',
    'Instrument Sans',
    'Instrument Serif',
    'Josefin Sans',
    'Josefin Slab',
    'Jost',
    'Kanit',
    'Lexend',
    'Lexend Deca',
    'Libre Baskerville',
    'Libre Franklin',
    'Literata',
    'Lusitana',
    'M PLUS 1p',
    'Merriweather',
    'Merriweather Sans',
    'Montserrat Alternates',
    'Noto Sans',
    'Noto Serif',
    'Noto Sans Display',
    'Noto Serif Display',
    'Noto Sans Mono',
    'Onest',
    'Oxygen',
    'PT Sans',
    'PT Serif',
    'PT Mono',
    'Playfair Display',
    'Plus Jakarta Sans',
    'Public Sans',
    'Righteous',
    'Rokkitt',
    'Saira',
    'Saira Condensed',
    'Sarabun',
    'Signika',
    'Signika Negative',
    'Space Grotesk',
    'Space Mono',
    'Spectral',
    'Spline Sans',
    'Sora',
    'Source Sans 3',
    'Source Serif 4',
    'Syne',
    'Tajawal',
    'Teko',
    'Titillium Web',
    'Trispace',
    'Ubuntu Condensed',
    'Varela Round',
    'Vollkorn',
    'Yanone Kaffeesatz',
    'Zilla Slab',
    'Alegreya',
    'Alegreya Sans',
    'Arimo',
    'Arvo',
    'Anton',
    'Bitter',
    'Cardo',
    'Cinzel',
    'Domine',
    'EB Garamond',
    'Eczar',
    'El Messiri',
    'Encode Sans',
    'Epilogue',
    'Fjalla One',
    'Forum',
    'Gilda Display',
    'Hanken Grotesk',
    'K2D',
    'Lora',
    'Marcellus',
    'Mate',
    'Maven Pro',
    'Newsreader',
    'Pacifico',
    'Prata',
    'Questrial',
    'Red Hat Display',
    'Red Hat Text',
    'Rethink Sans',
    'Satisfy',
    'Sen',
    'Staatliches',
    'Tenor Sans',
    'Unbounded',
    'Yeseva One',
    'Zeyada',
  ];

  static late final List<String> available = [
    ...legacy,
    ...candidates.where(GoogleFonts.asMap().containsKey),
  ];

  static bool accepts(String name) => available.contains(name);

  static TextStyle preview(String name,{TextStyle? base}) {
    final style=base ?? const TextStyle(fontSize:18);
    if(legacy.contains(name))return style.copyWith(fontFamily:name);
    if(!accepts(name))return style.copyWith(fontFamily:'Arial');
    return GoogleFonts.getFont(name,textStyle:style);
  }

  static TextTheme textTheme(String name,TextTheme original) {
    if(legacy.contains(name)||!accepts(name)){
      return original.apply(fontFamily:legacy.contains(name)?name:'Arial');
    }
    return GoogleFonts.getTextTheme(name,original);
  }
}

/// Searchable font selection popup: renders actual font faces only for visible
/// rows and lets the admin inspect typography without publishing anything.
class FittedFontMenu extends StatefulWidget {
  const FittedFontMenu({super.key,required this.current,required this.onSelected});
  final String current;
  final ValueChanged<String> onSelected;

  @override
  State<FittedFontMenu> createState()=>_FittedFontMenuState();
}
class _FittedFontMenuState extends State<FittedFontMenu>{
  final search=TextEditingController();
  @override
  void dispose(){search.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){
    return Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,
      children:[
        OutlinedButton(
          key:const Key('brand-font-dropdown'),
          onPressed:()=>_open(context),
          child:Row(children:[
            const Icon(Icons.font_download_outlined),const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text('Tipografía · ${FittedFontCatalog.available.length} familias',
                  style:Theme.of(context).textTheme.bodySmall),
                Text(widget.current,maxLines:1,overflow:TextOverflow.ellipsis,
                  style:FittedFontCatalog.preview(widget.current,base:
                    const TextStyle(fontSize:19,fontWeight:FontWeight.w600))),
              ])),
            const Icon(Icons.arrow_drop_down),
          ]),
        ),
      ]);
  }
  Future<void> _open(BuildContext context) async {
    search.clear();
    await showDialog<void>(context:context,builder:(ctx)=>StatefulBuilder(
      builder:(ctx,refresh){
        final fonts=FittedFontCatalog.available.where((f)=>
          f.toLowerCase().contains(search.text.trim().toLowerCase())).toList();
        return AlertDialog(
          title:const Text('Elegir tipografía'),
          content:SizedBox(width:460,height:440,child:Column(children:[
            TextField(key:const Key('brand-font-search'),controller:search,
              autofocus:true,
              onChanged:(_)=>refresh((){}),
              decoration:InputDecoration(
                prefixIcon:const Icon(Icons.search),
                hintText:'Buscar entre más de 100 fuentes',
                suffixIcon:IconButton(icon:const Icon(Icons.clear),
                  onPressed:(){search.clear();refresh((){});}))),
            const SizedBox(height:12),
            Expanded(child:ListView.builder(
              key:const Key('brand-font-results'),
              itemCount:fonts.length,
              itemBuilder:(ctx,i){
                final f=fonts[i];
                return ListTile(
                  key:Key('font-option-$f'),
                  selected:f==widget.current,
                  leading:Icon(f==widget.current
                    ?Icons.check_circle_outline:Icons.text_fields),
                  title:Text(f,maxLines:1,overflow:TextOverflow.ellipsis,
                    style:FittedFontCatalog.preview(f,base:
                      const TextStyle(fontSize:21,fontWeight:FontWeight.w500))),
                  subtitle:Text('Aa Bb Cc · 123 · ${f}',
                    maxLines:1,overflow:TextOverflow.ellipsis,
                    style:FittedFontCatalog.preview(f,base:
                      const TextStyle(fontSize:14))),
                  onTap:(){
                    widget.onSelected(f);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            )),
            if(fonts.isEmpty)const Text('No hay fuentes que coincidan.'),
          ])),
          actions:[TextButton(onPressed:()=>Navigator.of(ctx).pop(),
            child:const Text('Cerrar'))],
        );
      }));
  }
}
