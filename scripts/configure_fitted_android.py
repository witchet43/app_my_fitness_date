#!/usr/bin/env python3
"""Configure ephemeral Flutter Android project for the *real* Fitted app.

The repository keeps Flutter's shared source, not generated native project files.
Always run after 'flutter create --platforms=android'. No secrets baked in.
"""
import re
from pathlib import Path

ROOT=Path("apps/flutter_client")
manifest=ROOT/"android/app/src/main/AndroidManifest.xml"
text=manifest.read_text()
assert '<application' in text and '<activity' in text, "Generated native Android manifest missing"
# Make home-screen launcher brand Fitted, not the historical project slug.
text=re.sub(r'android:label="[^"]+"', 'android:label="Fitted"', text, count=1)
assert 'android:label="Fitted"' in text
if "android.permission.INTERNET" not in text:
    text=re.sub(
        r"(<manifest\b[^>]*>)",
        r'\1\n    <uses-permission android:name="android.permission.INTERNET" />',
        text,count=1)
# Flutter's Supabase SDK handles this deep link with PKCE and its own saved verifier.
# The same callback MUST be in Supabase Auth > URL Configuration > Redirect URLs.
callback='''            <!-- Android private sign-in return; browser login must not stay on the web. -->
            <intent-filter android:label="Fitted login callback">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="fitted"
                      android:host="auth"
                      android:pathPrefix="/callback" />
            </intent-filter>
'''
if "fitted" not in text or 'android:host="auth"' not in text:
    index=text.find("</activity>")
    assert index!=-1, "MainActivity closing tag is required"
    text=text[:index]+callback+"        "+text[index:]
manifest.write_text(text)
assert 'android:scheme="fitted"' in text
assert 'android:host="auth"' in text
assert 'android.permission.INTERNET' in text
assert 'android:exported="true"' in text
print("Android manifest: Fitted app, networking enabled, HTTPS APIs, native PKCE callback")

# Preserve explicit generated applicationId; it must remain stable for updates.
gradle=ROOT/"android/app/build.gradle.kts"
assert gradle.is_file(), "Expected generated Flutter Gradle Kotlin build file"
source=gradle.read_text()
assert 'applicationId' in source and 'com.fitted.my_fitness_date' in source, (
    "Unexpected Android application id — do not create an incompatible installer")
# Flutter default release signing with debug certificate is installable, NOT a
# verified Play Store distribution. The workflow records this in release notes.
print("Android package: com.fitted.my_fitness_date")
