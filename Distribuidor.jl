### Modulo encargado de distribuir los documentos
# En este caso corresponde a una instancia no distribuida de los agentes
# este emula la situacion del agente distribuidor

#### Benchmarks
include("estructuras.jl")
include("Tokenizer.jl")
include("Main.jl")

function giveElements(n::Int)
	numberElements = int(floor(n/length(ta.categorias)))
	f = []
	for cate in ta.categorias
		arch = splice!(Archivos[cate],1:numberElements)
		f = cat(1,f,arch)
	end	
	return f
end

function giveElements(n::Int,flag::Bool,Arch::Array)
	if flag
		f = splice!(Arch,1:n)
		#println(f)
		println(length(Arch))
		return f
	else
		return giveElements(n)
	end
end
function bench(flagH::Bool,flagP::Bool,flagTI::Bool,li::Int,sep::Int,numRank::Int,spVal::Float64,crVal::Float64,ite::Int)

#p = Pool()
#pools = Pool[]

resetPools(p,pools)
resetPool()
flagHistogram = flagH
flagPools = flagP
lim = li
separacion = sep
numRanking = numRank
flagTfIdf = flagTI
splitVal = spVal
critVal = crVal
iteracion = ite

dir = "../docs/twits"
t1 = Tabla()
t2 = Tabla()
weights = [1]
Archivos = Dict()
ta = Tabla()
ta.categorias = readdir(dir)
	files = []
	for cate in ta.categorias
		f = readdir(dir*"/"*cate)
		x = String[]
		for element in f
			files = cat(1,files,dir*"/"*cate*"/"*element)
			ta.indiceT[dir*"/"*cate*"/"*element] = cate
			push!(x,dir*"/"*cate*"/"*element)
		end
		Archivos[cate] = shuffle!(x)
	end
ta.files = files	
Arch = copy(files)
shuffle!(Arch)

#=#### Variables
flagHistogram = true
flagPools = false
lim = 10000
separacion = 300
numRanking = 0
flagTfIdf = true
splitVal = 0.7
critVal = 0.15

### Fin variables=#
### dir
 direcion = "$flagHistogram $flagPools $flagTfIdf $lim $separacion $numRanking $splitVal $critVal"
 #mkdir("./benchmarkResult/"*direcion)
 totalDir = "./benchmarkResult/"*direcion*"/iteracion $iteracion/"
 mkdir(totalDir)
 mkdir(totalDir*"hist/")
###
topVal = (3000/separacion) -1
t1 = initT(true,ta,separacion,lim,Arch)
splitTrainTest(t1,splitVal)
if flagPools
	trainPools(t1)
	res = testPools(t1,t1.Test,weights)
else
	train(t1)
	res = test(t1,t1.Test)
end
hist = histogram2(t1,1,t1.textos)
fileHistogram(hist,totalDir,0)
res = create_file(res,0,totalDir*"iteracion 0.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t1)
for i in 1:topVal
	t2 = initT(true,ta,separacion,lim,Arch)
	#updateDiccWithRanking!(t2,400,true)
	if flagHistogram
		val = dHistogramsWords(t1,t2,numRanking,flagTfIdf)
		crit = val
	else
		val = tTestWords(t1,t2,numRanking,flagTfIdf)
		crit = criticalValue(val)
	end
	#println(crit)
	if flagPools
		res2 = testPools(t2,t2.files,weights)
	else
		res2 = test(t2,t2.files)
	end
	res2 = create_file(res2,crit,totalDir*"iteracion $i.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t2)
	
	if crit > critVal
		
		splitTrainTest(t2,splitVal)
		println("Añadiendo tablas 1 y 2")
		t1 = addTablas(t1,t2)
		hist = histogram2(t1,1,t1.textos)
		fileHistogram(hist,totalDir,i)
		#updateDiccWithRanking!(t1,400,true)
		if flagPools
			trainPools(t2)
			weights = updateWeights(weights,(1-res2))
			res3 = testPools(t2,t2.Test,weights)
			
		else
			if t1.textos > t1.limTextos
				removeFiles(t1)
				trainLim(t1)
			else
				train(t2)
			end
			res3 = test(t2,t2.Test)
		end
		
		
		res3 = create_file(res3,crit,totalDir*"iteracion $i retrained.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t2)
		
		println("iteracion:$i valor de tTest: $crit, re-entrenar f1:$res2 , f1 nuevo: $res3 ")
		
		
	else
		println("iteracion:$i valor de tTest: $crit, no re-entrenar f1: $res2")
	end
end
end