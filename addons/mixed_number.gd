extends RefCounted

class_name MixedNumber

# 带分数的整数部分
var whole: int = 0
# 分数的分子
var numerator: int = 0
# 分数的分母
var denominator: int = 1

# 构造函数 ===================================================================================================================================================================
func _init(new_whole: int = 0, new_numerator: int = 0, new_denominator: int = 1):
	self.whole = new_whole
	self.numerator = new_numerator
	self.denominator = new_denominator
	# 初始化后化简带分数
	self.simplify()

# 输出 ===================================================================================================================================================================
# 将带分数转换为浮点数
func num_to_float() -> float:
	return float(self.whole) + float(self.numerator) / float(self.denominator)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 将带分数转换为字符串表示形式
func num_to_string() -> String:
	return str(self.whole) + ":" + str(self.numerator) + "/" + str(self.denominator) # 正常的带分数字符串
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 将带分数转换为数组
func num_to_array() -> Array:
	return [whole, numerator, denominator]

# 输入 ===================================================================================================================================================================
# 将 string 代表的分数解析并赋值到当前对象中
func from_string(fraction_str: String) -> Error:
	
	# 移除字符串中的多余空格
	var trimmed_str = fraction_str.strip_edges()

	# 分解输入字符串
	if ":" in trimmed_str:
		# 形式: "整数:分子/分母" (带整数部分)
		var parts = trimmed_str.split(":")
		whole = int(parts[0])                           # 提取整数部分
		var fraction_parts = parts[1].split("/")       # 提取分子/分母部分
		numerator = int(fraction_parts[0])             # 分子
		denominator = int(fraction_parts[1])           # 分母
	elif "/" in trimmed_str:
		# 形式: "分子/分母" (没有整数部分的纯分数)
		whole = 0                                      # 整数部分默认为 0
		var fraction_parts = trimmed_str.split("/")
		numerator = int(fraction_parts[0])             # 分子
		denominator = int(fraction_parts[1])           # 分母
	else:
		# 形式: "整数" (只有整数部分的情况)
		whole = int(trimmed_str)                       # 只提取整数部分
		numerator = 0                                  # 分子默认为 0
		denominator = 1                                # 分母默认为 1

	# 验证分母是否为零
	if denominator == 0:
		whole = 0
		numerator = 0
		denominator = 1
		push_error("分母不得为0！已设为默认值。")
		
	self.simplify()
	return Error.OK
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 将 float 代表的分数解析并赋值到当前对象中
func from_float(value: float, new_denominator: int) -> void:
	# 确保分母合法
	if denominator == 0:
		push_error("分母不得为0！已重置为默认值1。")
		self.whole = 0
		self.numerator = 0
		self.denominator = 1
		return

	# 提取整数部分
	self.whole = int(value)
	var decimal_part = value - self.whole  # 小数部分

	# 计算分子
	self.numerator = round(decimal_part * new_denominator)
	# 赋值分母
	self.denominator = new_denominator

	# 化简分数
	self.simplify()
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 将 array 代表的分数解析并赋值到当前对象中
func from_array(arr: Array) -> void:
	self.whole = arr[0]
	self.numerator = arr[1]
	self.denominator = arr[2]
	
	self.simplify()

# 赋值方法 ===================================================================================================================================================================
# 直接设置三值
func set_num(whole: int, numerator: int, denominator: int):
	self.whole = whole
	self.numerator = numerator
	self.denominator = denominator
	self.simplify()
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 从另一个对象拷贝
func copy_num(other: MixedNumber):
	self.whole = other.whole
	self.numerator = other.numerator
	self.denominator = other.denominator
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 从另一个对象相加
func self_add(other: MixedNumber) -> void:
	var result: MixedNumber = add(self, other)
	self.from_array([result.whole, result.numerator, result.denominator])
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 从另一个对象相减
func self_subtract(other: MixedNumber) -> void:
	var result: MixedNumber = subtract(self, other)
	self.from_array([result.whole, result.numerator, result.denominator])

# 辅助函数 ===================================================================================================================================================================
func simplify():
	if self.denominator == 0:
		push_error("分母不得为0！") # 分母不能为零
		return

	if self.numerator == 0:
		self.whole = self.whole # 如果分子为0，重置可能的假分数状态。确保整数部分正确。
		self.denominator = 1 # 分母设为1
		return

	# 计算分子和分母的最大公约数
	var gcd_val = gcd(self.numerator, self.denominator)
	# 用最大公约数约分
	self.numerator /= gcd_val
	self.denominator /= gcd_val

	# 将假分数转换为带分数
	if abs(self.numerator) >= self.denominator:
		self.whole += self.numerator / self.denominator
		self.numerator = abs(self.numerator) % self.denominator

	#if self.numerator < 0:  # 确保分子始终为正数
		#self.numerator = abs(self.numerator)

	if self.numerator == 0: # 如果分子化简后为0，则分母设为1
		self.denominator = 1

# 静态函数 ===================================================================================================================================================================
## 检查一个字符串是否符合带分数的表示格式
static func is_valid_format(input: String) -> bool:  
	# 定义正则表达式，确保 "整数:整数/整数" 的格式  
	var regex = RegEx.new()  
	# 模式说明：  
	# - ^\d+：确保以一段整数开头  
	# - :\d+：紧接一个冒号和整数  
	# - /\d+：紧接一个斜杠和整数  
	# - $：最后确保字符串以该格式结束  
	regex.compile(r"^\d+:\d+/\d+$")  

	# 使用正则表达式匹配输入字符串，如果匹配则返回 true  
	return regex.search(input) != null  
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## 计算最大公约数 (使用欧几里得算法)
static func gcd(a: int, b: int) -> int:
	a = abs(a)
	b = abs(b)
	while b:
		var temp = a % b
		a = b
		b = temp
	return a

## 计算最小公倍数
static func lcm(a: int, b: int) -> int:  
	return abs(a * b) / gcd(a, b)

## 从不同类型新建对象
static func new_from_string(fraction_str: String) -> MixedNumber:
	var result: MixedNumber = MixedNumber.new()
	if is_valid_format(fraction_str) or fraction_str.is_valid_int():
		result.from_string(fraction_str)
		return result
	else:
		push_error("新建带分数时输入格式错误")
		return result
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
static func new_from_array(arr: Array) -> MixedNumber:
	var result: MixedNumber = MixedNumber.new()
	result.from_array(arr)
	return result
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
static func new_from_float(value: float, new_denominator: int) -> MixedNumber:
	var result: MixedNumber = MixedNumber.new()
	result.from_float(value, new_denominator)
	return result
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## 直接从数组转为小数
static func arr_to_float(arr: Array) -> float:
	var value: MixedNumber = MixedNumber.new()
	value.from_array(arr)
	return value.num_to_float()

## 将两个带分数相加
static func add(num1: MixedNumber, num2: MixedNumber) -> MixedNumber:  
	# 初始化结果  
	var result: MixedNumber = MixedNumber.new()  

	# 将两个带分数统一为分数形式  
	var common_denominator = lcm(num1.denominator, num2.denominator)  # 求最小公倍数  
	  
	var numerator1: int = num1.whole * num1.denominator + num1.numerator  # 第一个带分数转假分数  
	var numerator2: int = num2.whole * num2.denominator + num2.numerator  # 第二个带分数转假分数  
	  
	# 转换为统一分母的分子  
	numerator1 *= int(common_denominator / num1.denominator)  
	numerator2 *= int(common_denominator / num2.denominator)
	  
	# 合并分子和分母  
	var final_numerator = numerator1 + numerator2  
	var final_denominator = common_denominator  
	  
	# 将结果转为带分数形式  
	result.whole = final_numerator / final_denominator  # 整数部分  
	result.numerator = final_numerator % final_denominator  # 分子部分  
	result.denominator = final_denominator  # 分母部分  
	  
	# 简化带分数  
	result.simplify()  
	  
	return result

## 将两个带分数相减
static func subtract(num1: MixedNumber, num2: MixedNumber) -> MixedNumber:  
	# 初始化结果  
	var result: MixedNumber = MixedNumber.new()  

	# 将两个带分数统一为分数形式  
	var common_denominator = lcm(num1.denominator, num2.denominator)  # 求最小公倍数  
	
	var numerator1: int = num1.whole * num1.denominator + num1.numerator  # 第一个带分数转假分数  
	var numerator2: int = num2.whole * num2.denominator + num2.numerator  # 第二个带分数转假分数  
	
	# 转换为统一分母的分子  
	numerator1 *= int(common_denominator / num1.denominator)  
	numerator2 *= int(common_denominator / num2.denominator)
	
	# 合并分子和分母  
	var final_numerator = numerator1 - numerator2  
	var final_denominator = common_denominator  
	
	# 将结果转为带分数形式  
	result.whole = final_numerator / final_denominator  # 整数部分  
	result.numerator = final_numerator % final_denominator  # 分子部分  
	result.denominator = final_denominator  # 分母部分  
	
	# 简化带分数  
	result.simplify()  
	
	return result
