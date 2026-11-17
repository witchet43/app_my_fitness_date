-- Only explicitly approved public font families can be published. Preview is local.
-- Keep original Arial/Georgia/Palatino/Garamond versions rollback-compatible.
begin;
create or replace function app_private.valid_mfd_brand(p_settings jsonb)
returns boolean
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_key text;
  v_value text;
begin
  if p_settings is null or jsonb_typeof(p_settings) <> 'object'
     or pg_column_size(p_settings) > 8192 then
    return false;
  end if;
  for v_key in select jsonb_object_keys(p_settings) loop
    if v_key <> all(array[
      'name','tagline','title','description','paletteName',
      'colors','font','logo','media','mode','layout'
    ]) then return false; end if;
  end loop;
  if char_length(btrim(coalesce(p_settings->>'name',''))) not between 2 and 60 or
     char_length(coalesce(p_settings->>'tagline','')) not between 2 and 120 or
     char_length(coalesce(p_settings->>'title','')) not between 8 and 180 or
     char_length(coalesce(p_settings->>'description','')) not between 10 and 600 or
     char_length(coalesce(p_settings->>'paletteName','')) not between 2 and 70 or
     coalesce(p_settings->>'font','') <> all(array[
    'Georgia',
    'Palatino',
    'Garamond',
    'Arial',
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
    'Zeyada'
  ]) or
     coalesce(p_settings->>'mode','') <> all(array['dark','light']) or
     coalesce(p_settings->>'layout','') <> all(array['editorial','minimal'])
  then return false; end if;

  if jsonb_typeof(p_settings->'colors') <> 'object' or
     coalesce(p_settings->'colors'->>'primary','') !~ '^#[0-9a-fA-F]{6}$' or
     coalesce(p_settings->'colors'->>'accent','') !~ '^#[0-9a-fA-F]{6}$' or
     coalesce(p_settings->'colors'->>'background','') !~ '^#[0-9a-fA-F]{6}$'
  then return false; end if;

  if coalesce(p_settings->>'logo','') !~ '^catalog:([0-9]|1[0-9]|20)$'
     and not app_private.is_safe_mfd_public_asset(p_settings->>'logo')
  then return false; end if;

  if jsonb_typeof(p_settings->'media') <> 'object' or
     (select count(*) from jsonb_object_keys(p_settings->'media')) > 3
  then return false; end if;

  for v_key,v_value in
    select key,value from jsonb_each_text(p_settings->'media')
  loop
    if v_key <> all(array['cover_desktop','cover_mobile','app_image'])
      or not app_private.is_safe_mfd_public_asset(v_value)
    then return false; end if;
  end loop;
  return true;
end;
$$;

commit;
