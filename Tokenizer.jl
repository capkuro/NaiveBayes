### Tokenizer comple las funciones del agente critico
### utiliza la estructura tabla para poder realizar y almacenar todas las operaciones.


include("util.jl")
include("estructuras.jl")

function initT(dir::String)
return initT(dir,0.0)
end

function initT(bool::Bool,ta::Tabla,num::Int,limT::Int,Arch::Array)
	t = Tabla()
	t.categorias = ta.categorias
	t.indiceT =  ta.indiceT
	t.files = giveElements(num,true,Arch)
	t.limTextos = limT
	text2vector(t,t.files)
	return t
end
function splitTrainTest(t::Tabla,limSuperior::Float64)
	t.Test = splice!(t.files,int((t.textos*limSuperior)+1):t.textos)
	t.textos -= t.textos*(1-limSuperior)
end
function addTablas(t1::Tabla,t2::Tabla)
	tablaAux = Tabla()
	tablaAux.categorias = t1.categorias
	tablaAux.indiceT = t1.indiceT
	tablaAux.files = cat(1,t1.files,t2.files)
	tablaAux.limTextos = t1.limTextos
	text2vector(tablaAux,tablaAux.files)
	return tablaAux
end
function removeFiles(t1::Tabla)
	n = t1.textos-t1.limTextos
	splice!(t1.files,1:n)
	t1.textos = t1.limTextos
end


function initT(dir::String,limitWords::Int,flagIdf::Bool)
	t = Tabla()
	t.categorias = readdir(dir)
	files = []
	for cate in t.categorias
		f = readdir(dir*"/"*cate)
		for element in f
			files = cat(1,files,dir*"/"*cate*"/"*element)
			t.indiceT[dir*"/"*cate*"/"*element] = cate
		end
	end
	
	
	t.files = shuffle!(files)
	text2vector(t,t.files)
	#updateDiccWithRanking!(t,limitWords,flagIdf)
	#t.limitTest = limititTest
	#a = itTest(t,5)
	a = iHistogram(t,5)
	#println(t.textos)
	t.limSuperior = a[1]
	t.limInferior = a[2]
	t.porcentaje = a[3]

	return t

end
function fileHistogram(Hist::Array,dir::String,iteracion)
	file = open(dir*"hist/histograma $iteracion .txt","w")
	for linea in Hist
		println(file,linea)
	end
	close(file)
end
function tokenizer(Diccionario::Dict,texto::String)
	est = estandarizar(texto)
	i = 1
	splitted = split(est)
	for word in splitted
		if !haskey(Diccionario,word)
			#println(word*" palabra numero: "*string(Diccionario.count + 1))
			Diccionario[word] = Diccionario.count + 1
		end		
	end
	return Diccionario
end

function textsInput()
	Diccionario = Dict()
	files = readdir("./Textos")
	for file in files
		f = open("./Textos/"*file)
		Diccionario = tokenizer(Diccionario,readall(f))
		close(f)
	end
	return Diccionario
end
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

function textsInput(dir::String)
	Diccionario = Dict()
	categories = readdir("./"*dir)	
	for cat in categories
		files = readdir("./"*dir*"/"*cat)	
	end
	
	for file in files
		f = open("./"*dir*"/"*cat*"/"file)
		Diccionario = tokenizer(Diccionario,readall(f))
		close(f)
	end
	return Diccionario
end

function text2vector(test::Bool,dir::String)

	if test
		Dicc = textsInput()
		x = length(readdir("./Textos/"))
		vector = zeros(Int,x*Dicc.count)
		updateVector!(vector,Dicc)
		return vector
	else
		Dicc = textsInput(dir)
		x = length(readdir("./Textos/"))
		vector = zeros(Int,x*Dicc.count)
		updateVector!(vector,Dicc)
		return vector
	end
end

function text2vector(t::Tabla,Arr::Array)
		shuffle!(Arr)	
		t.Diccionario = textsInput(Arr)
		t.textos = length(Arr)
		t.frequencias = zeros(Int,t.textos,t.Diccionario.count)
		t.promedios= zeros(Float64,t.Diccionario.count)
		t.desv= zeros(Float64,t.Diccionario.count)
		updateVector!(t.frequencias,t.Diccionario,Arr)
	
end

function text2vector(t::Tabla,test::Bool,dir::String)
	shuffle!(files)
	if test
		t.Diccionario = textsInput()
		t.textos = length(readdir("./Textos/"))
		t.frequencias = zeros(Int,t.textos,t.Diccionario.count)
		t.promedios= zeros(Float64,t.Diccionario.count)
		t.desv= zeros(Float64,t.Diccionario.count)
		updateVector!(t.frequencias,t.Diccionario)
	else
		Dicc = textsInput(dir)
		x = length(readdir("./Textos/"))
		vector = zeros(Int,x*Dicc.count)
		vector = reshape(vector,x,Dicc.count)
		updateVector!(vector,Dicc)
	end
end
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

function tTest1(t::Tabla)

	x1 = mean(t.promedios[1:t.textos/2])
	x2 = mean(t.promedios[floor(t.textos/2)+1:t.textos])
	s1 = std(t.promedios[1:t.textos/2])
	s2 = std(t.promedios[floor(t.textos/2)+1:t.textos])
	s12 = ((s1^2)/(t.textos/2)) + ((s2^2)/(t.textos/2))
	s12 = sqrt(s12)
	tTest = (x1-x2)/s12
	return tTest
end

function tTestWords(t::Tabla)
	tTest = zeros(Float64,t.Diccionario.count)
	for i in 1:t.Diccionario.count
		x1 = mean(t.frequencias[1:t.textos/2,i])
		x2 = mean(t.frequencias[floor(t.textos/2)+1:t.textos,i])
		s1 = std(t.frequencias[1:t.textos/2,i])
		s2 = std(t.frequencias[floor(t.textos/2)+1:t.textos,i])
		s12 = ((s1^2)/(t.textos/2)) + ((s2^2)/(t.textos/2))
		s12 = sqrt(s12)
		tTest[i] = (x1-x2)/s12
	end
	return tTest
end

function tTestWords(t::Tabla,n1::Float64,n2::Float64)
	tTest = zeros(Float64,t.Diccionario.count)
	for i in 1:t.Diccionario.count
		x1 = mean(t.frequencias[1:t.textos*n1,i])
		x2 = mean(t.frequencias[floor(t.textos*n1)+1:t.textos,i])
		s1 = std(t.frequencias[1:t.textos*n1,i])
		s2 = std(t.frequencias[floor(t.textos*n1)+1:t.textos,i])
		if t.varianzas[i] < 0.764 || t.varianzas[i] > 1.284
			s12 = ((s1^2)/(t.textos*n1)) + ((s2^2)/(t.textos*n2))
			s12 = sqrt(s12)
		else
			s12 = (((t.textos*n1)-1)*(s1^2) + ((t.textos*n2)-1)*(s2^2))/((t.textos*n1)+(t.textos*n2)-2)
			#s12 = sqrt(s12)*sqrt(((1/(t.textos*n1))+(1/(t.textos*n2))
		end
		
		tTest[i] = (x1-x2)/s12
	end
	return tTest
end
##### ESTE ES EL IMPORTANTE f1234
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

function histogram(t::Tabla,n1::Int,n2::Int)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[1,:])
	tablaAux.frequencias = t.frequencias[n1:n2,:]
	hist = ranking(tablaAux,n)
	return hist
end
function histogram2(t::Tabla,n1::Int,n2::Int)
	tablaAux = Tabla()
	tablaAux.Diccionario = t.Diccionario
	n = length(t.frequencias[1,:])
	tablaAux.frequencias = t.frequencias[n1:n2,:]
	hist = ranking2(tablaAux,n)
	return hist
end
##### FIN DEL IMPORTANTE


function criticalValue(Arr::Array)
i = 0
	for el in Arr
		if el < -0.968 || el > 1.968
			i += 1
		end
	end
return (i/length(Arr))

end
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

function itTest(t::Tabla,maxIteration::Int)
	a = 0
	b = 0
	mintTest = 1
	for i in 1:maxIteration
		for j in 0:i-1
		updateVariance!(t,(j+1)/(i+1),(i-j)/(i+1))
		test = tTestWords(t,(j+1)/(i+1),(i-j)/(i+1))
		x = criticalValue(test)
		if x < mintTest
			mintTest = x
			a = (j+1)/(i+1)
			b = (i-j)/(i+1)
		end
	end
		
	end	
	println("tstudent mas normal: $mintTest, a:$a, b:$b")
	return [a,b,mintTest]
end
function iHistogram(t::Tabla,maxIteration::Int)
	a = 0
	b = 0
	mintTest = 1
	for i in 1:maxIteration
		for j in 0:i-1
		hist1 =histogram(t,(j+1)/(i+1),false,t.Diccionario.count)
		hist2 = histogram(t,(j+1)/(i+1),true,t.Diccionario.count)
		test = distHistogram(hist1,hist2)
		
		if abs(test) < mintTest
			mintTest = abs(test)
			a = (j+1)/(i+1)
			b = (i-j)/(i+1)
		end
	end
		
	end	
	println("diferencia de histogramas menor: $mintTest, a:$a, b:$b")
	return [a,b,mintTest]
end

function iHistogram(t::Tabla,maxIteration::Int,Tipo::Int)
	a = 0
	b = 0
	mintTest = 1
	for i in 1:maxIteration
		for j in 0:i-1
		hist1 =histogram(t,(j+1)/(i+1),false,t.Diccionario.count)
		hist2 = histogram(t,(j+1)/(i+1),true,t.Diccionario.count)
		test = distHistogram(hist1,hist2,Tipo)
		
		if abs(test) < mintTest
			mintTest = abs(test)
			a = (j+1)/(i+1)
			b = (i-j)/(i+1)
		end
	end
		
	end	
	println("diferencia de histogramas menor: $mintTest, a:$a, b:$b")
	return [a,b,mintTest]
end
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
##Ranking palabras mas repetidas
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
##Ranking con tf-idf
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
### Funcion que obtiene Inverse document frecuency
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
### Funcion que obtiene el term frequency - inverse document frequency
### https://en.wikipedia.org/wiki/Tf%E2%80%93idf
function tfidf(t::Tabla)
	tfIdf = zeros(Float64,t.textos,t.Diccionario.count)
	Idf = zeros (Float64,t.Diccionario.count)	
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

### Funcion que obtiene distancia (diferencia) entre dos histogramas
### Entrega 3 tipos distintos de distancias 
### Distancia de sorensen https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient

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

### Funcion que obtiene distancia (diferencia) entre dos histogramas
### Entrega 3 tipos distintos de distancias 
### Distancia de sorensen https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient

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