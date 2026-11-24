# NULL — THE LIVING TOUCH

مشروع لعبة Godot 4.7.2 مخصص للهاتف، يعمل محلياً دون حساب أو API مدفوع.

## تشغيل اللعبة
1. افتح هذا المستودع في Godot 4.7.2 Stable أو أحدث.
2. افتح `project.godot` وشغّل المشهد الرئيسي.
3. تحكم باللمس: Tap وAnchor وSwipe وCurve وLoop وPulse Train.
4. تقدم القصة يتكون من 6 مراحل، مع Survival وDaily وEvolution Lab وسجل الاكتشافات.

## بناء APK من GitHub
كل Push إلى `main` يشغّل سير GitHub Actions:
- تثبيت Godot 4.7.2 Stable وقوالب Android المطابقة.
- تجهيز OpenJDK 17 وAndroid SDK.
- تشغيل فحوص Python واختبارات GDScript.
- تصدير APK Debug لمعمارية ARM64.
- رفع APK كـ Workflow Artifact وإنشاء Pre-release يحتوي ملف APK.

افتح تبويب **Actions** لمتابعة حالة البناء. عند نجاحه، افتح **Releases** وحمّل أحدث ملف `NULL-debug.apk`.

## بناء محلي
يجب تجهيز Android SDK / JDK 17 وقوالب تصدير Godot المطابقة. ثم:
```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --export-debug Android build/NULL-debug.apk
```

نسخة Debug للاختبار فقط. النشر في Google Play يحتاج توقيع Release بمفتاح خاص تحتفظ به بأمان.

## النطاق والحدود
- اللعب محلي Offline؛ لا توجد حسابات أو لعب جماعي أو ترتيب عالمي مباشر.
- TOUCH DNA قواعد حتمية، وليس نموذج تعلم آلي.
- يجب تشغيل APK على أجهزة Android فعلية واختبار الأداء واللمس قبل أي إطلاق عام.
