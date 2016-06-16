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
flagStopwords =[true, false]
flagHistogram =[false, true]
flagPools = [false]
flagTfIdf = [false, true]
limites = [300,600,1000,1500,2000,10000]
separacion = [100,150,300,600,1000]
numRanking =[0,100,500,1000]
#splitVal = [0.9]
splitVal = [0.9,0.7,0.5]
critVal =[0.1,0.15,0.2,0.25,0.3,0.5]
#umbral = [500]
for flSp in flagStopwords
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
									for i in 1:10
										bench(flSp,flH,flP,flTI,lim,sep,numr,spl,crv,i)
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
end