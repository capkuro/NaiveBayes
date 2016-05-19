### 
# Tokenizer comple las funciones del agente critico
# utiliza la estructura tabla para poder realizar y almacenar todas las operaciones.
###

###
#
include("util.jl")
include("estructuras.jl")

###
# Inicializar tabla con un directorio, hace referencia a la funcion inicializar tabla con 2 elementos.
function initT(dir::AbstractString)
	return initT(dir,0.0)
end
# Inicializar tabla con una direccion, el limite de palabras maximo  
# y si se utilizara tf-idf para hacer la comparacion en reduccion de dimensionalidad
# esta corresponde a una version anterior de la initT
###

###
# Funcion de inicializar tabla, la cual es la que se utiliza en distribuidor.jl
# Todos los parametros necesarios son pasados por los argumentos
# 
###
function initT(bool::Bool,ta::Tabla,num::Int,limT::Int,Arch::Array)
	t = Tabla()
	t.categorias = ta.categorias
	t.indiceT =  ta.indiceT
	#Funcion giveElements implementada en distribuidor.jl
	t.files = giveElements(num,true,Arch)
	t.limTextos = limT
	text2vector(t,t.files)
	return t
end

###
#Funcion fileHistogram, realiza un output a un archivo de un histograma de las palabras. (https://es.wikipedia.org/wiki/Histograma)
###
function fileHistogram(Hist::Array,dir::AbstractString,iteracion)
	file = open(dir*"hist/histograma $iteracion .txt","w")
	for linea in Hist
		println(file,linea)
	end
	close(file)
end

###
#tokenizer: crea un diccionario con las frecuencias de cada palabra en un texto
#Luego de estandarizarlo genera un diccionario con la posicion de cada palabra en un futuro arreglo que se creara
#llamado por textsInput 
###
function tokenizer(Diccionario::Dict,texto::AbstractString)
	est = estandarizar(texto)
	splitted = split(est)
	for word in splitted
		if !haskey(Diccionario,word)
			Diccionario[word] = Diccionario.count + 1
		end		
	end
	return Diccionario
end

###
#textsInput: Genera un diccionario con la posicion de las palabras para 
#todos los archivos contenidos en Arr (iterando a traves de todos los archivos)
#llamado por text2vector
###
function textsInput(Arr::Array)
	Diccionario = Dict()
	
	shuffle(Arr)
	for file in Arr
		f = open(file)
		Diccionario = tokenizer(Diccionario,readall(f))
		#
		close(f)
	end
	return Diccionario
end

###
#Genera e inicializa el contenido para las tablas, considerando los archivos de entrada
# - Genera una bagOfWords para la tabla de todos los documentos (t.Diccionario = textsInput(Arr))
# - Obtiene la cantidad de textos/twits con los que se va a trabajar, entrenar.
# - Inicializa vectores con las frequencias, promedios y desviaciones estandard para cada palabra (estas ultimas dos en relacion a la frecuencia) 
# - Actualiza las frecuencias totales para cada palabra (updateVector!(t.frequencias,t.Diccionario,Arr))
###
function text2vector(t::Tabla,Arr::Array)
		shuffle!(Arr)	
		t.Diccionario = textsInput(Arr)
		t.textos = length(Arr)
		t.frequencias = zeros(Int,t.textos,t.Diccionario.count)
		t.promedios= zeros(Float64,t.Diccionario.count)
		t.desv= zeros(Float64,t.Diccionario.count)
		updateVector!(t.frequencias,t.Diccionario,Arr)
	
end

###
#actualiza un vector el cual contiene todas las palabras para todos los documentos/textos (arreglo Arr)
#para obtener las frecuencias totales para todas las palabras en todos los documentos.
###
function updateVector!(vector::Array,Dicc::Dict,Arr::Array)
	i=1
	for file in Arr
		f = open(file)
		texto = split(estandarizar(readall(f)))
		for word in texto
			if haskey(Dicc,word)
				indice = Dicc[word]
				vector[i,indice ] += 1
			end
		end
		i += 1
		close(f)
		
	end
	##println(reshape(vector,i,Dicc.count))
end

###
#funcion que actualiza todos los promedios y desviaciones estandard para cada palabra
#segun su frecuencia en todo el corpus de textos
###
function updateMeanStd(t::Tabla)
	i = int(1)
	#while i <= t.textos 
	for i in 1:t.textos
		prom = mean(t.frequencias[i,:])
		dev = std(t.frequencias[i,:])
		t.promedios[i] = prom		
		t.desv[i] = dev
		i += 1
	end
end

###
# tTestWords: funcion qque genera una tabla auxiliar para obtener los valores indice t-student
# para todas las pabras en el corpus de textos (textos que estan en el conocimiento del 
# clasificador, y comparandolos con los textos del conjunto nuevo)
# el procedimiento para calcular estos valores son
# - creo una tabla temporal la cual contiene los archivos de ambas tablas
# - si es que hay que utilizar ranking de palabras, genero el ranking de las N palabras mas importantes (n = numRanking)
# - obtengo todos los textos (indices en files) que corresponden para cada conjunto (n1 y n2)
# - actualizo las varianzas para dichos conjuntos con el fin de obtener el valor critico de la prueba F-test_of_equality_of_variances para cada palabra.
# - obtengo el promedio y las deviasones estandard para cada palabra
# - comparo el valor critico de la prueba F-test_of_equality_of_variances para saber cual formula de t-student ocupar (https://en.wikipedia.org/wiki/Student%27s_t-test#Independent_two-sample_t-test)
# -obtengo el valor t para la palabra i.
# - retorno un arreglo con los valores t para todas las palabras del conjuntos de textos (texto1 + texto2)
###
function tTestWords(t1::Tabla,t2::Tabla,numRanking::Int,tfIdf::Bool)
	tabla_temporal = Tabla()
	tabla_temporal.categorias = t1.categorias
	tabla_temporal.indiceT = t1.indiceT
	tabla_temporal.files = cat(1,t1.files,t2.files)
	text2vector(tabla_temporal,tabla_temporal.files)
	if numRanking >0
		updateDiccWithRanking!(tabla_temporal,numRanking,tfIdf)
	end
	tTest = zeros(Float64,tabla_temporal.Diccionario.count)
	n1 = t1.textos/(t1.textos+t2.textos)
	n2 = t2.textos/(t1.textos+t2.textos)
	t = tabla_temporal
	updateVariance!(t,n1,n2)
	for i in 1:tabla_temporal.Diccionario.count
		x1 = mean(t.frequencias[1:t.textos*n1,i])
		x2 = mean(t.frequencias[floor(t.textos*n1)+1:t.textos,i])
		s1 = std(t.frequencias[1:t.textos*n1,i])
		s2 = std(t.frequencias[floor(t.textos*n1)+1:t.textos,i])
		if t.varianzas[i] < 0.775 || t.varianzas[i] > 1.283
			s12 = ((s1^2)/(t.textos*n1)) + ((s2^2)/(t.textos*n2))
			s12 = sqrt(s12)
		else
			s12 = (((t.textos*n1)-1)*(s1^2) + ((t.textos*n2)-1)*(s2^2))/((t.textos*n1)+(t.textos*n2)-2)
		end
		
		tTest[i] = (x1-x2)/s12
	end
	return tTest
end

###
#Este calcula la distancia 
###
function dHistogramsWords(t1::Tabla,t2::Tabla,numRanking::Int,tfIdf::Bool)
	tabla_temporal = Tabla()
	tabla_temporal.categorias = t1.categorias
	tabla_temporal.indiceT = t1.indiceT
	tabla_temporal.files = cat(1,t1.files,t2.files)
	text2vector(tabla_temporal,tabla_temporal.files)
	if numRanking >0
		updateDiccWithRanking!(tabla_temporal,numRanking,tfIdf)
	end
	n1 =t1.textos
	n2 =tabla_temporal.textos-t1.textos + 1
	hist1 = histogram(tabla_temporal,1,n1)
	hist2 = histogram(tabla_temporal,n2,tabla_temporal.textos)
	diff = distHistogram(hist1,hist2)
	return diff
end


##### FIN DEL IMPORTANTE

###
# Ve si el valor esta contenido entre 2 puntos de una tabla de distribuciones
# (valores mas altos de una tabla de t-student), con el fin de ver cuantos elementos del
# arreglo Arr, exceden los limites de un intervalo de confianza del 95% en una prueba de dos colas.)
# retorna el porcentaje del total de elementos los cuales excenden los valores criticos
###
function criticalValue(Arr::Array)
i = 0
	for el in Arr
		if el < -0.968 || el > 1.968
			i += 1
		end
	end
return (i/length(Arr))

end

###
# Prueba F de varianzas. (https://en.wikipedia.org/wiki/F-test_of_equality_of_variances)
# Esta funcion realiza un test de hipotesis donde calcula que tan iguales son las varianzas
###
function varianceTest(t::Tabla,n1::Float64,n2::Float64)
	vTest = zeros(Float64,t.Diccionario.count)
	for i in 1:t.Diccionario.count
		s1 = std(t.frequencias[1:t.textos*n1,i])
		s2 = std(t.frequencias[floor(t.textos*n1)+1:t.textos,i])
		if s1 == 0
			s1 = 0.0001
		end
		if s2 == 0
			s2 = 0.0001
		end
		#if(s1>s2)
			vTest[i] = s1^2/s2^2
		#else
		#	vTest[i] = s2^2/s1^2
		#end
	end
	return vTest
end
###
# Actualiza las varianzas para cada palabra entre dos conjuntos de textos  en una tabla
# llama a la funcion de prueba de varianzas
###
function updateVariance!(t::Tabla,n1::Float64,n2::Float64)
	t.varianzas = varianceTest(t,n1,n2)
end
function tTest2(t::Tabla,n1::Float64,n2::Float64)

	x1 = mean(t.promedios[1:floor(t.Diccionario.count*n1)])
	x2 = mean(t.promedios[floor(t.Diccionario.count*n1)+1:t.Diccionario.count])
	s1 = std(t.promedios[1:floor(t.Diccionario.count*n1)])
	s2 = std(t.promedios[floor(t.Diccionario.count*n1)+1:t.Diccionario.count])
	s12 = ((s1^2)/(t.Diccionario.count*n1)) + ((s2^2)/(t.Diccionario.count*n2))
	s12 = sqrt(s12)
	tTest = (x1-x2)/s12
	return tTest
	
end

###
#
###
function toTuple(t::Tabla)
	dicc = Dict()
	freq = zeros(Int,t.Diccionario.count)
	for i in 1: t.Diccionario.count
		freq[i] = sum(t.frequencias[:,i])
	end
	for key in keys(t.Diccionario)

		dicc[key] = freq[t.Diccionario[key]]
	end
	arr = collect(dicc)
	return arr
end

###
#Obtener el ranking con tf-idf
###
function rankingTfIdf(Diccionario::Dict,tfIdf::Array,indice::Int)
	dicc = Dict()
	n = length(tfIdf[1,:])
	scores = zeros(Float64,n)
	for i in 1:length(tfIdf[1,:])
		scores[i] = sum(tfIdf[:,i])*idf(tfIdf[:,i])
	end
	for key in keys(Diccionario)
		dicc[key] = scores[Diccionario[key]]
	end
	arr = sort(collect(dicc),by = tuple -> last(tuple),rev=true)[1:indice]
	return arr
end

###
#Ranking palabras mas repetidas (mayor frecuencia) con ranking de palabras
###+
function updateDiccWithRanking!(t::Tabla,indice::Int)
	arr = ranking(t,indice)
	Dicc = Dict()
	i = 1
	for tupla in arr
		Dicc[tupla[1]] = i
		i += 1
	end
	t.Diccionario = Dicc
	t.frequencias = zeros(Int,t.textos,t.Diccionario.count)
	t.promedios= zeros(Float64,t.textos)
	t.desv= zeros(Float64,t.textos)
	updateVector!(t.frequencias,t.Diccionario,t.files)
end

###
#Ranking con tf-idf
###
function updateDiccWithRanking!(t::Tabla,indice::Int,bool::Bool)
println("Dicc with ranking $indice, $bool para tfidf")
	if !bool
		updateDiccWithRanking!(t,indice)
	else
		tfIdfMatrix = tfidf(t)
		arr = rankingTfIdf(t.Diccionario,tfIdfMatrix,indice)
		Dicc = Dict()
		i = 1
		for tupla in arr
			Dicc[tupla[1]] = i
			i += 1
		end
		println(Dicc.count)
		t.Diccionario = Dicc
		t.frequencias = zeros(Int,t.textos,t.Diccionario.count)
		t.promedios= zeros(Float64,t.textos)
		t.desv= zeros(Float64,t.textos)
		updateVector!(t.frequencias,t.Diccionario,t.files)
	end
end

### 
#Funcion que obtiene Inverse document frecuency
###
function idf(ar::Array)
	N = length(ar)
	count = 0
	for el in ar
		if el !=0
			count +=1
		end
	end
	val = log10(N/count)
	return val
end

### 
#Funcion que obtiene el term frequency - inverse document frequency (https://en.wikipedia.org/wiki/Tf%E2%80%93idf)
#retorna una matriz con los pesos tf-idf calculadoss
### 
function tfidf(t::Tabla)
	tfIdf = zeros(Float64,t.textos,t.Diccionario.count)
	Idf = zeros(Float64,t.Diccionario.count)	
	for i in 1:t.textos
		for j in 1:t.Diccionario.count
			if t.frequencias[1,:] != 0
				tfIdf[i,:] = log10(1 + t.frequencias[i,:]) * Idf(t.frequencias[i,:])
			else
				tfIdf[i,:] = 0
			end
		end
	end
	for j in 1:t.Diccionario.count
		Idf[j] = idf(t.frequencias[:,j])
		tfIdf[:,j] *= Idf[j]
	end
	return tfIdf
end

###
#obtiene el histograma segun dos indices (n1 y n2) para luego aplicar ranking
###
function histogram(t::Tabla,n1::Int,n2::Int)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[1,:])
	tablaAux.frequencias = t.frequencias[n1:n2,:]
	hist = ranking(tablaAux,n)
	return hist
end

###
# obtiene el histograma segun el corte superior o inferior y se le aplica el ranking
###
function histogram(t::Tabla,n1::Float64,Bottom::Bool,indice::Int)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[:,1])
	if Bottom
		tablaAux.frequencias = t.frequencias[floor(n*n1):n,:]
	else
		tablaAux.frequencias = t.frequencias[1:floor(n*n1),:]
	end
	hist = ranking(tablaAux,indice)
	return hist
end

###
#Ranking entrega las N palabras con la frecuencia relativa (freq/total) (indice = N)
###
function ranking(t::Tabla,indice::Int)
	dicc = Dict()
	freq = zeros(Int,t.Diccionario.count)
	
	for i in 1: t.Diccionario.count
		freq[i] = sum(t.frequencias[:,i])
	end
	total = sum(freq)
	freq = freq/total
	for key in keys(t.Diccionario)

		dicc[key] = freq[t.Diccionario[key]]
	end
	arr = sort(collect(dicc),by = tuple -> last(tuple),rev=true)[1:indice]
	return arr
end

###
# Histograma2 retorna un histograma utilizando la funcion de ranking2 (frecuencias de palabras)
###
function histogram2(t::Tabla,n1::Float64,Bottom::Bool,indice::Int)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[:,1])
	if Bottom
		tablaAux.frequencias = t.frequencias[floor(n*n1):n,:]
	else
		tablaAux.frequencias = t.frequencias[1:floor(n*n1),:]
	end
	hist = ranking2(tablaAux,indice)
	return hist
end

###
# Este entrega las N palabras con mayor frecuencia en toda la tabla. (N = indice)
###
function ranking2(t::Tabla,indice::Int)
	dicc = Dict()
	freq = zeros(Int,t.Diccionario.count)
	
	for i in 1: t.Diccionario.count
		freq[i] = sum(t.frequencias[:,i])
	end
	total = sum(freq)
	for key in keys(t.Diccionario)

		dicc[key] = freq[t.Diccionario[key]]
	end
	arr = sort(collect(dicc),by = tuple -> last(tuple),rev=true)[1:indice]
	return arr
end

###
# Obtener el histograma de una tabla sin realizar ranking
###
function histogramWithoutRanking(t::Tabla,n1::Float64,Bottom::Bool)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[:,1])
	if Bottom
		tablaAux.frequencias = t.frequencias[floor(n*n1):n,:]
	else
		tablaAux.frequencias = t.frequencias[1:floor(n*n1),:]
	end
	hist = toTuple(tablaAux)
	return hist
end

###
# Funcion que obtiene distancia (diferencia) entre dos histogramas
# Entrega 3 tipos distintos de distancias 
# Distancia de sorensen https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient
###
function distHistogram(Arr1::Array,Arr2::Array)
	dicc = Dict()
	i = 1
	for tupla in Arr1
		dicc[tupla[1]] = i
		i+=1
	end
	for tupla in Arr2
		if !haskey(dicc,tupla[1])
			dicc[tupla[1]] = i
			i+=1
		end
	end
	hist1= zeros(Float64,(dicc.count))
	hist2= zeros(Float64,(dicc.count))
	
	for tupla in Arr1
		hist1[dicc[tupla[1]]] = tupla[2]
	end

	for tupla in Arr2
		hist2[dicc[tupla[1]]] = tupla[2]
	end
	dist = (sum(abs(hist1-hist2)))/(sum(hist1+hist2))
	return dist
end

###
# Funcion que obtiene distancia (diferencia) entre dos histogramas
# Entrega 3 tipos distintos de distancias 
# Distancia de sorensen https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient
###
function distHistogram(Arr1::Array,Arr2::Array,tipo::Int)
	dicc = Dict()
	i = 1
	for tupla in Arr1
		dicc[tupla[1]] = i
		i+=1
	end
	for tupla in Arr2
		if !haskey(dicc,tupla[1])
			dicc[tupla[1]] = i
			i+=1
		end
	end
	
	hist1= zeros(Int,(dicc.count))
	hist2= zeros(Int,(dicc.count))
	
	for tupla in Arr1
		hist1[dicc[tupla[1]]] = tupla[2]
	end

	for tupla in Arr2
		hist2[dicc[tupla[1]]] = tupla[2]
	end
	if tipo == 1
		dist = (sum(abs(hist1-hist2)))/(sum(hist1+hist2))
	end
	if tipo == 2
		dist = (sum(abs(hist1-hist2)))/(sum(max(hist1,hist2)))
	end
	if tipo == 3
		dist = (sum(abs(hist1-hist2)))/(sum(min(hist1,hist2)))		
	end
	return dist
end