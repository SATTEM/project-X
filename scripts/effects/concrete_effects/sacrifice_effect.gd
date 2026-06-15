class_name SacrificeEffect
extends EffectResource
## 献祭效果：处决一个友方随从，并根据其费用返还能量


func apply(_user: Character, target: Character) -> void:
	# 安全校验：确保目标是怪物，且是己方随从
	if target is Monster and target.is_ally:
		# 计算返还能量（随从基础召唤费用的一半，向下取整）
		var return_energy: int = int(target.summon_cost * 0.5)
		
		# 给玩家加能量
		if BattleManager.player:
			BattleManager.player.energy = min(
				BattleManager.player.energy + return_energy, 
				BattleManager.player.max_energy
			)
			BattleManager.player.energy_changed.emit(BattleManager.player.energy)
			print("献祭卡牌生效！处决了随从 [", target.name, "]，返还能量：", return_energy)
			
		# 赋予致死量，触发原有的死亡清理机制
		target.health = 0
	else:
		print("目标不合法，献祭失败！")


func get_value() -> int:
	## 满足 EffectResource 基类的抽象方法要求
	## 献祭的收益是动态计算的，没有固定静态数值，返回 0 即可
	return 0
