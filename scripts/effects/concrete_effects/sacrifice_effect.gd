class_name SacrificeEffect
extends EffectResource
## 献祭效果：处决一个友方随从，并根据其费用返还能量


func apply(user: Character, target: Character) -> void:
	# 只允许玩家献祭仍存活的友方随从，不能误伤玩家或敌人。
	if not user is Player or not target is Monster or not target.is_ally or target.is_dead:
		push_warning("献祭目标不合法，效果未结算。")
		return

	var player := user as Player
	# 返还召唤费用的一半，向上取整且至少返还1点能量。
	var return_energy := maxi(1, ceili(float(target.summon_cost) * 0.5))
	var gained_energy := player.gain_energy(return_energy)
	print(
		"献祭卡牌生效！处决了随从 [", target.name,
		"]，请求返还：", return_energy, "，实际返还：", gained_energy
	)

	# 通过生命归零触发 BattleManager 的标准死亡、队列和站位清理流程。
	target.health = 0


func get_value() -> int:
	## 满足 EffectResource 基类的抽象方法要求
	## 献祭的收益是动态计算的，没有固定静态数值，返回 0 即可
	return 0
