extends RefCounted
class_name GameCatalog

const MISSIONS: Array[Dictionary] = [
	{"id":"first_pulse","title":"النبضة الأولى","subtitle":"علّم الضوء طريقه","goal":"ارسم مساراً يبدأ من LUMA وينتهي عند RELAY.","hint":"ابدأ اللمسة فوق الكائن الأزرق، ثم اسحب إلى العقدة الزرقاء البعيدة.","reward":20,"steps":["اكتشف LUMA","ارسم مساراً","فعّل البوابة"]},
	{"id":"veyl_orbit","title":"مدار VEYL","subtitle":"الحماية تبدأ من حلقة","goal":"ارسم حلقة مغلقة حول النواة SEED.","hint":"ارسم دائرة كاملة حول النواة الذهبية، واجعل بداية الحلقة ونهايتها متقاربتين.","reward":25,"steps":["راقب النواة","ارسم المدار","ثبّت الحماية"]},
	{"id":"echo_signal","title":"إشارة ECHO","subtitle":"الإيقاع يصنع الاستجابة","goal":"المس ECHO ثلاث مرات بإيقاع سريع.","hint":"نفّذ ثلاث نقرات منفصلة على الكائن البنفسجي خلال فترة قصيرة.","reward":30,"steps":["اقترب من ECHO","أنشئ قطار نبضات","أيقظ العقدة"]},
	{"id":"transfer","title":"نقل البصمة","subtitle":"السلوك لا يبقى في مكانه","goal":"علّم LUMA المسار إلى RELAY، ثم أيقظ ECHO بنقرة.","hint":"أكمل المسار أولاً. بعد ظهور رسالة نجاح النقل، انقر على ECHO.","reward":35,"steps":["تعليم LUMA","نقل الإشارة","إيقاظ ECHO"]},
	{"id":"hush_trap","title":"فخ HUSH","subtitle":"اجعل الخطر يتبع ما تريد","goal":"ثبّت الطُعم ثم ارسم مداراً حول HUSH.","hint":"اضغط مطولاً على DECOY أولاً، ثم ارسم حلقة حول الكائن الداكن HUSH.","reward":40,"steps":["ثبّت الطُعم","اجذب HUSH","أغلق المدار"]},
	{"id":"resonance_gate","title":"بوابة الرنين","subtitle":"ثلاث إشارات، عالم واحد","goal":"أكمل المسار، ثم المدار، ثم قطار النبضات.","hint":"بالترتيب: LUMA إلى RELAY، حلقة حول SEED، ثم ثلاث نقرات على ECHO.","reward":60,"steps":["المسار","المدار","قطار النبضات"]}
]

static func mission(index: int) -> Dictionary:
	return MISSIONS[clampi(index, 0, MISSIONS.size() - 1)].duplicate(true)

static func daily_mission_index(date_string: String) -> int:
	var total := 0
	for i in date_string.length():
		total += date_string.unicode_at(i) * (i + 3)
	return total % MISSIONS.size()

static func species() -> Array[Dictionary]:
	return [
		{"id":"LUMA","name":"لوما","role":"يتبع المسارات الضوئية","color":Color(0.20,0.88,1.0)},
		{"id":"VEYL","name":"فيل","role":"يصنع مدارات الحماية","color":Color(0.72,0.35,1.0)},
		{"id":"ECHO","name":"إيكو","role":"يعيد الإشارات بإيقاعها","color":Color(1.0,0.63,0.23)}
	]
