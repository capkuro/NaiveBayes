### 
# Funcion de benchmark para poder ver el rendimiento del clasificador y 
# Re-training con distintas configuraciones de clasificaciones mediante
# fuerza bruta en las posibles combinaciones de parametros.
###

# Incluye distribuidor.jl el que basicamente realiza funciones del agente distribuidor de los documentos
# para el agente critico y el agente clasificador. A su vez, distribuidor.jl incluye:
# - Estructuras.jl -> Estructuras basicas para el funcionamiento del clasificador naive bayes y el critico
# - Tokenizer.jl -> Netamente el agente critico
# - Main.jl ->  Netamente el agente clasificador
include("Distribuidor.jl")


batch = [0]
data = Array(Tuple,1)


umbral = [0]
flagHistogram =[false]
flagPools = [false]
flagTfIdf = [true]
limites = [1000]
separacion = [300]
numRanking =[0]
splitVal = [0.7]
#splitVal = [0.8,0.7,0.5]
critVal =[0.25]
#umbral = [500]
for flH in flagHistogram
	for flP in flagPools
		for flTI in flagTfIdf
			for lim in limites
				for sep in separacion
					for numr in numRanking
						for spl in splitVal
							for crv in critVal
							#direcion = "$flH $flP $flTI $lim $sep $numr $spl $crv"
							#mkdir("./benchmarkResult/"*direcion)
								for i in 1:1
									bench(flH,flP,flTI,lim,sep,numr,spl,crv,i)
									#pools y p corresponden a la estructura Pools la cual alberga el clasificador y sus funcionalidades
									#
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
