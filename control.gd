extends Node

@export var xml_file: String = "":
	set(p):
		xml_file = p
		if p and FileAccess.file_exists(p):
			_parse_and_export(p)

func _on_file_selected(path: String) -> void:
	xml_file = path

func _parse_and_export(path: String) -> void:
	var data_dic: Dictionary
	var doc := XML.parse_file(path)
	var root: XMLNode = doc.root
	data_dic = root.to_dict()
	
	var bpms_arr: Array = _find_points_arr(data_dic)
	
	var json_str: String = JSON.stringify(make_bpm_list_from_warps(bpms_arr), "\t")
	var out_path: String = path.get_base_dir().path_join("bpmList.json")
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(json_str)
	f.close()
	
	print("已在同目录下输出“bpmList.json”。")
	print("共输出 {0} 条BPM。".format([bpms_arr.size()]))
	

func _find_points_arr(project_dic: Dictionary) -> Array:
	return project_dic["children"]["Arrangement"]["children"]["Lanes"]["children"]["Lanes"][0]["children"]["Clips"]["children"]["Clip"]["children"]["Clips"]["children"]["Clip"]["children"]["Warps"]["children"]["Warp"]

# 输入：Warp 锚点数组（Dictionary 列表）
# 输出：{ "bpmList": [ { "sTime":[...], "bpm":..., "secTime":0 }, ... ] }
func make_bpm_list_from_warps(warps: Array) -> Dictionary:
	var bpm_list: Array[Dictionary] = []
	for i in warps.size() - 1:
		var w1 = warps[i]
		var w2 = warps[i + 1]

		var t1: float = w1.attrs.time.to_float()
		var s1: float = w1.attrs.contentTime.to_float()
		var t2: float = w2.attrs.time.to_float()
		var s2: float = w2.attrs.contentTime.to_float()

		var bpm: float = (t2 - t1) / (s2 - s1) * 60.0
		var frac: Array[int] = _beat_to_fraction(t1)

		bpm_list.append({
			"bpm": bpm,
			"startTime": frac,
		})
	#refresh_bpm_list_sec(bpm_list)
	
	return {"bpmList": bpm_list}

# ---------- 辅助：小数 beat → 带分数 ----------
func _beat_to_fraction(beat: float) -> Array[int]:
	const EPS := 1e-6
	var whole: int = int(beat)
	var rem: float = beat - whole
	if abs(rem) < EPS:
		return [whole, 0, 1]
	for d in range(1, 101):
		var n := int(round(rem * float(d)))
		if abs(float(n) / float(d) - rem) < EPS:
			var g := _gcd(n, d)
			return [whole, n / g, d / g]
	return [whole, int(round(rem * 100.0)), 100]

func _gcd(a: int, b: int) -> int:
	return a if b == 0 else _gcd(b, a % b)

func refresh_bpm_list_sec(bpm_list: Array):

	for i in range(1, bpm_list.size()):
		var stime_step = MixedNumber.arr_to_float(bpm_list[i]['sTime']) - MixedNumber.arr_to_float(bpm_list[i - 1]['sTime'])
		bpm_list[i]['secTime'] = bpm_list[i - 1]['secTime'] + btime_to_sec(stime_step, bpm_list[i - 1]['bpm'])

func btime_to_sec(btime: float, bpm: float) -> float:
	return btime / bpm * 60
