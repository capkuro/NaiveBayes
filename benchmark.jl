#include("critico.jl")

include("Distribuidor.jl")


batch = [0]
data = Array(Tuple,1)


umbral = [0]
flagHistogram =[true]
flagPools = [false]
flagTfIdf = [true]
limites = [10000]
separacion = [150]
numRanking =[0]
splitVal = [0.7]
#splitVal = [0.8,0.7,0.5]
critVal =[0.9]
#umbral = [500]
for flH in flagHistogram
	for flP in flagPools
		for flTI in flagTfIdf
			for lim in limites
				for sep in separacion
					for numr in numRanking
						for spl in splitVal
							for crv in critVal
							direcion = "$flH $flP $flTI $lim $sep $numr $spl $crv"
							mkdir("./benchmarkResult/"*direcion)
								for i in 1:1
									bench(flH,flP,flTI,lim,sep,numr,spl,crv,i)
									p = Pool()
									pools = Pool[]	
								end
							end
						end
					end
				end
			end
		end
	end
end
