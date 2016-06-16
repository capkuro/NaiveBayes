### Modulo encargado de distribuir los documentos
# En este caso corresponde a una instancia no distribuida de los agentes
# este emula la situacion del agente distribuidor

### 
# Modulo encargado de distribuir los documentos
# Corresponde a la implementacion no distribuida como agentes de software, 
# si no mas bien a la instancia iterativa del agente distribuidor
###

# Distribuidor.jl incluye:
# - Estructuras.jl -> Estructuras basicas para el funcionamiento del clasificador naive bayes y el critico
# - Tokenizer.jl -> Funcionalidades del agente critico
# - Main.jl ->  Funcionalidades el agente clasificador
include("estructuras.jl")
include("Tokenizer.jl")
include("Main.jl")

#La funciones giveElements asemejan el comportamient oque tiene que tener el agente distribuidor para entregar los documentos 
#en las distintas N etapas temporales(entregar de por ejemplo 300 documentos por iteracion temporal)
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
### 
# Funcion bench (benchmark) 
# flagH: Flag histograma - Booleano -> Realizar comparación de histogramas para el re-entrenamiento.
# flagP: Flag Pools - Booleano -> Utilizar varias pools 
function bench(flagSp::Bool,flagH::Bool,flagP::Bool,flagTI::Bool,li::Int,sep::Int,numRank::Int,spVal::Float64,crVal::Float64,ite::Int)
	#p = Pool()
	#pools = Pool[]
	#Reinicio las pools entre iteración del benchmark, asi evitar que conocimiento previo entre iteracion con distinas configuraciones
	#p y pools son variables globales que se crean en main.jl (despues de los include)
	resetPools(p,pools)
	resetPool()
	#Inicializo las variables de configuracion para dicha instancia
	global flagStop = flagSp
	flagHistogram = flagH
	flagPools = flagP
	lim = li
	separacion = sep
	numRanking = numRank
	flagTfIdf = flagTI
	splitVal = spVal
	critVal = crVal
	iteracion = ite

	dir = "./docs/twits"
	t1 = Tabla()
	t2 = Tabla()
	weights = [1]
	Archivos = Dict()
	#ta -> tablaAuxiliar
	ta = Tabla()
	#Leo el directorio donde esta el dataset repartido en carpetas con el fin de obtener las distintas categorias
	ta.categorias = readdir(dir)
	files = []
	#Leo los archivos dentro de cada carpeta para cada categoria
	for cate in ta.categorias
		f = readdir(dir*"/"*cate)
		x = String[]
		for element in f
			files = cat(1,files,dir*"/"*cate*"/"*element)
			#Guardo en un diccionario la categoria para dicho archivo
			ta.indiceT[dir*"/"*cate*"/"*element] = cate
			push!(x,dir*"/"*cate*"/"*element)
		end
		#Diccionario de archivos por categoria, es distinto a indiceT, ya que archivos se utiliza para el entrenamiento / testing
		Archivos[cate] = shuffle!(x)
	end
	ta.files = files	
	Arch = copy(files)
	shuffle!(Arch)

	#=#### Variables esto esta comentado
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
	if flagHistogram
		direccion = "Histogram/"
	else
		direccion= "tstudent/"
	end
	direcion = direccion*"$flagSp $flagHistogram $flagPools $flagTfIdf $lim $separacion $numRanking $splitVal $critVal"
	if !isdir("./benchmarkResult/"*direcion)
		mkdir("./benchmarkResult/"*direcion)
	end
	 
	totalDir = "./benchmarkResult/"*direcion*"/iteracion $iteracion/"
	if !isdir(totalDir)
		mkdir(totalDir)
	end
	if !isdir(totalDir*"hist/")
		mkdir(totalDir*"hist/")
	end
	###
	#Valor tope
	topVal = (3000/separacion) -1
	#Inicializo la tabla1
	t1 = initT(true,ta,separacion,lim,Arch)
	#Divido los archivos en archivos de entrenamiento y de testing
	splitTrainTest(t1,splitVal)

	#Si flagPools es verdadero, se utiliza un conjunto o ensemble de clasificadores
	#Hasta el dia de hoy las pools como ensemble no funcionan o reportan baja exactitud de clasificacion
	if flagPools
		trainPools(t1)
		res = testPools(t1,t1.Test,weights)
	else
		#entreno y testeo con el set de pruebas
		train(t1)
		res = test(t1,t1.Test)
	end
	#Obtengo el histograma 
	hist = histogram2(t1,1.0,false,length(t1.frequencias[1,:]))
	#Lo guardo en un archuivo
	fileHistogram(hist,totalDir,0)
	res = create_file(res,0,0,totalDir*"results.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t1)
	for i in 1:topVal
		#Inicializo la segunda tabla
		t2 = initT(true,ta,separacion,lim,Arch)
		#updateDiccWithRanking!(t2,400,true)
		#Si flagHistogram es true, realizo la comparacion para re-entrenar con distancia de histogramas, sino, lo realizo con la comparacion
		#De los valores t-student
		if flagHistogram
			val = dHistogramsWords(t1,t2,numRanking,flagTfIdf)
			crit = val
		else
			val = tTestWords(t1,t2,numRanking,flagTfIdf)
			crit = criticalValue(val)
		end
		#println(crit)
		#Realizo el testeo del conjunto de documentos para testing una vez que el clasificador 1 fue entrenado (con los datos de la tabla t1)
		if flagPools
			res2 = testPools(t2,t2.files,weights)
		else
			res2 = test(t2,t2.files)
		end
		#guardo los resultados
		res2 = create_file(res2,crit,i,totalDir*"results.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t2)
		
		#Si el valor de la diferencia/valor t-student excede un valor umbral, se inicia el proceso de re-entrenamiento
		if crit > critVal
			
			#divido en training y testing la tabla 2
			splitTrainTest(t2,splitVal)
			println("Añadiendo tablas 1 y 2")
			#sumo las tablas t1 y t2 (despues de haber separado la tabla 2, solo se añaden los archivos que quedan en t2.files y no los de t2.testing)
			
			t1 = addTablas(t1,t2)
			#Genero un nuevo histograma para guardar
			hist = histogram2(t1,1.0,false,length(t1.frequencias[1,:]))
			
			fileHistogram(hist,totalDir,i)
			#updateDiccWithRanking!(t1,400,true)
			#si FlagPools, entreno un clasificador nuevo y lo dejo en arreglo de clasificadores (Pools)
			if flagPools
				trainPools(t2)
				#Los pesos se actualizan para los clasificadores (esto es debido a que en algunos papers, mencionan que el conocimiento 
				#mas reciente es el que mas importa, por lo que, la salida de cada clasificador con conocimiento mas antiguo debe reducirse para
				#cumplir con lo descrito anteriormente)
				weights = updateWeights(weights,(1-res2))
				#Realizo los archivos de testing, 
				res3 = testPools(t2,t2.Test,weights)
				
			else
			#De lo contrario veo si existe un limite de textos (Almacenar un maximo de N textos para el conocimiento de clasificador)
				if t1.textos > t1.limTextos
					#Elimino los textos mas antiguos de la lista del clasificador
					removeFiles(t1)
					#Entreno con el limite de textos (Implica desechar el clasificador/modelo anterior para crear uno nuevo con los textos limite)
					trainLim(t1)
				else
					#De lo contrario añado el conocimiento al clasificador
					train(t2)
				end
				#Obtengo el nuevo resultado del set de testing, con el conocimiento uevo integrado
				res3 = test(t2,t2.Test)
			end
			
			#Creo el archivo de output para los resultados del clasificador
			res3 = create_file(res3,crit,i,totalDir*"retrained.txt","Flag histogram: $flagHistogram Flag Pools: $flagPools Limite de textos:$lim separacion: $separacion numRanking: $numRanking splitVal: $splitVal val Critico: $critVal",t2)
			
			println("iteracion:$i valor de tTest: $crit, re-entrenar f1:$res2 , f1 nuevo: $res3 ")
			
			
		else
			println("iteracion:$i valor de tTest: $crit, no re-entrenar f1: $res2")
		end
	end
end