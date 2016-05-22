# Definición de estructuras basicas para el funcionamiento de la estructura.
include("util.jl")

##Tabla y sus metodos
abstract tabla
### Tabla es la estructura que contiene todos los elementos para el calculo del re-entrenamiento (Agente Critico)
type Tabla <: tabla
	Diccionario::Dict
	indiceT::Dict ##
	categorias::Array
	files::Array
	Test::Array
	frequencias::Array
	promedios::Array
	varianzas::Array
	desv::Array
	limTextos::Int
	porcentaje::Float64
	limSuperior::Float64
	limInferior::Float64
	limitTest::Float64
	textos::Int
end

#Constructor de la tabla
function Tabla()
	table = Tabla(Dict(),Dict(),[0],[0],[0],[0],[0],[0],[0],0,0,0,0,0,0)
	return table
end
###
# Funcion de inicializar tabla, la cual es la que se utiliza en distribuidor.jl
# Todos los parametros necesarios son pasados por los argumentos
# 
###
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
	t.files = giveElements(num,bool,Arch)
	t.limTextos = limT
	text2vector(t,t.files)
	return t
end
function initT(bool::Bool,ta::Tabla,num::Int,limT::Int)
	t = Tabla()
	t.categorias = ta.categorias
	t.indiceT =  ta.indiceT
	#Funcion giveElements implementada en distribuidor.jl
	t.files = giveElements(num,true,Arch)
	t.limTextos = limT
	text2vector(t,t.files)
	return t
end
# Hacer split del conjunto de textos
function splitTrainTest(t::Tabla,limSuperior::Float64)
	t.Test = splice!(t.files,int((t.textos*limSuperior)+1):t.textos)
	t.textos -= t.textos*(1-limSuperior)
end
#
function Add_word(table::tabla,word::AbstractString)
	if !haskey(table.t,word)
		table.numeroPalabras += 1
		table.t[word] = table.numeroPalabras
	end
end

#
function addTablas(t1::Tabla,t2::Tabla)
	tablaAux = Tabla()
	tablaAux.categorias = t1.categorias
	tablaAux.indiceT = t1.indiceT
	tablaAux.files = cat(1,t1.files,t2.files)
	tablaAux.limTextos = t1.limTextos
	text2vector(tablaAux,tablaAux.files)
	return tablaAux
end

#
function removeFiles(t1::Tabla)
	n = t1.textos-t1.limTextos
	splice!(t1.files,1:n)
	t1.textos = t1.limTextos
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

######=================================================================================================

###
# BagOfWords y sus metodos
# Esta es la implementacion de la bolsa de palabras (https://en.wikipedia.org/wiki/Bag-of-words_model)
# A diferencia del link de wikipedia, esta bolsa de palabras se implementa mediante un diccionario,
# lo que permite la adicion de nuevas palabras de manera mas sencilla para las operaciones de entrenamiento / re-entrenamiento.
###
abstract bagOfWords

type BagOfWords <: bagOfWords
	NumeroPalabras::Int
	Bag_of_words::Dict
end

### Constructor
function BagOfWords()
	bag = BagOfWords(0,Dict())
	return bag
end
##Sumar / concatenar 2 bagOfWords
function add(bag1::bagOfWords,bag2::bagOfWords)
	erg = BagOfWords()
	sum = erg.Bag_of_words
	for key in keys(bag1.Bag_of_words)
		sum[key] = get(bag1.Bag_of_words,key,0)
		if haskey(bag2.Bag_of_words,key)
			sum[key] += get(bag2.Bag_of_words,key,0)
		end
	end
	for key in keys(bag2.Bag_of_words)
		if !(haskey(sum,key))
			sum[key] = get(bag2.Bag_of_words,key,0)
		end
	end
	erg.NumeroPalabras = bag1.NumeroPalabras + bag2.NumeroPalabras
	return erg
end
### Añadir palabra a la bag of words
function add_word(bag::bagOfWords,word::AbstractString)
	bag.NumeroPalabras +=1
	if haskey(bag.Bag_of_words,word)
		bag.Bag_of_words[word] += 1
	else
		bag.Bag_of_words[word] = 1
	end
end

#Obtener todas las palabras para dicha bag of words
function palabras(bag::bagOfWords)
	return keys(bag.Bag_of_words)
end

# Obtener el diccionario para dicha bolsa.
function bolsa(bag::bagOfWords)
	return bag.Bag_of_words
end

#Obtener la frecuencia de la palabra (cuantas veces existe)
function frecuenciaPalabra(bag::bagOfWords,word::AbstractString)
	if haskey(bag.Bag_of_words,word)
		return bag.Bag_of_words[word]
	else
		return 0
	end
end

######=================================================================================================

## Document y sus metodos

abstract Doc

type Document <: Doc
	nombre::AbstractString
	clase::AbstractString
	palabras_y_freq::BagOfWords
	vocabulario::BagOfWords
end


function Document()
	doc = Document("","",BagOfWords(),BagOfWords())
	return doc
end

#Constructor de documento, incorporando el p.vocabulario (vocabulario global)
function Document(vocab::BagOfWords)
	doc = Document("","",BagOfWords(),vocab)
	return doc
end
#Sumar  / concatenar 2 documentos
function add(doc1::Document, doc2::Document)
	res = Document()
	res.vocabulario = doc1.vocabulario
	res.palabras_y_freq = add(doc1.palabras_y_freq,doc2.palabras_y_freq)
	return res
end
# Intersectar 2 documentos
function and(doc1::Document, doc2::Document) 
	interseccion = String[]
	keys1 = palabras(doc1)
	for word in palabras(doc2)
		if word in keys1
			push!(interseccion,word)
		end
	end
	return interseccion	
end
#Leer un documento y añadir las palabras al vocabulario del documento y al vocabulario global (p.vocabulario)
function leer_document(doc::Document,texto::AbstractString, aprender::Bool)
	##Preprocesar los textos
	words = estandarizar(texto)
	#words = removerNumeros(words)
	#words = removerStopWords(words)

	words = split(words)

	for word in words
		add_word(doc.palabras_y_freq,word)
		if aprender
			add_word(doc.vocabulario,word)
		end
	end
end
# Obtener el tamaño del vocabulario para dicho documento
function tamano_vocabulario(doc::Document)
	return length(doc.vocabulario)
end
#Obtener las palabras y la frecuencias para dichas palabras del documento (bagofWord del documento)
function palabrasYFreq(doc::Document)
	return bolsa(doc.palabras_y_freq)
end
#Obtener las palabras del documento
function palabras(doc::Document)
	bag = bolsa(doc.palabras_y_freq)
	return keys(bag)
end
#Obtener la frecuencia para una palabra del documento
function frecuenciaPalabra(doc::Document,word::AbstractString)
	bag = bolsa(doc.palabras_y_freq)
	if haskey(bag,word)
		return bag[word]
	else
		return 0
	end
end

######=================================================================================================

###
# Document Class y sus documents (documentos ligados a una clase)
###
abstract documentClass

type DocumentClass <: documentClass
	documento::Document
	number_of_docs::Int
end

function DocumentClass()
	DC = DocumentClass(Document(),0)
	return DC
end
#Constructor DocumentClass inicializandolo con un documento
function DocumentClass(doc::Document)
	DC = DocumentClass(doc,0)
	return DC
end

#probabilidad de documentClass obtiene la probabilidad de que ina palabra pertenesca a dicha clase
function probabilidad(dc::DocumentClass,word::AbstractString)
	voc_len = tamano_vocabulario(dc.documento)
	SumN = frecuenciaPalabra(dc.documento.vocabulario,word)
	N = frecuenciaPalabra(dc.documento,word)
	
	erg =  N / (voc_len + SumN)
	return erg
end
### sumar / Concatenar 2 documentos
function add(dc1::DocumentClass,dc2::DocumentClass)
	res = DocumentClass()
	res.documento = add(dc1.documento,dc2.documento)
	res.number_of_docs = dc1.number_of_docs + dc2.number_of_docs
	return res
end
#Obtener las palabras y frecuencia para la documentClass
function palabrasYFreq(dc1::DocumentClass)
	return palabrasYFreq(dc1.documento)
end
##
##Obtener la frecuencia de una palabra en la documentClass
function frecuenciaPalabra(doc::DocumentClass,word::AbstractString)
	return frecuenciaPalabra(doc.documento,word)
end

######=================================================================================================

### 
# Pool y sus metodos
# Pool es en esencia el clasificador bayes ingenuo
# clases: Diccionario("String","DocumentClass") -> Se utiliza para guardar las clases, y las palabras que existen dentro de esa clase, (DocumentClass) para cada clase.
# vocabulario: BagOfWords -> Se utiliza para obtener todo el vocabulario del bayes ingenuo y poder realizar el calculo.
###
abstract pool
type Pool <: pool
	clases:: Dict
	vocabulario::BagOfWords
end

# Constructor de Pool
function Pool()
	p = Pool(Dict(),BagOfWords())
	return p
end

###
# Suma todas las cantidades de palabras que existen para una clase.
###
function sum_words_in_class(p::Pool,dclass::AbstractString)
	sum = 0
	for word in palabras(p.vocabulario)
		WaF = palabrasYFreq(p.clases[dclass])
		if haskey(WaF,word)
			sum += WaF[word]
		end
	end
	return sum
end

###
# Funcion learn: Encargada de incorporar las palabras de los documentos para dicha clase, al clasificador
# Recibe la Pool donde se va a insertar dichos documentos (palabras), el directorio donde se encuentran dichos documentos
# Y a la clase la cual pertenecen dichos documentos
# Esto incorpora el conocimiento mediante la adicion incremental del vocabulario a la clase y el vocabulario global. 
# Cuando se llama a p.vocabulario, este hace referencia al vocabulario global entre todas las clases.
# esto funciona principalmente por que en julia se pasan referencias a los objetos, por lo que algun cambio
# añadiendo algo a la categoria 1, tambien afecta al p.vocabulario de la categoria 2.
###
function learn(p::Pool,directory::AbstractString,dclass_name::AbstractString)
	x = DocumentClass(Document(p.vocabulario))
	dir = readdir(directory)
	for file in dir
		f = open(directory*"/"*file)
		d = Document(p.vocabulario)
		println(directory*"/"*file)
		leer_document(d,readall(f),true)
		x.documento = add(x.documento,d)
		p.clases[dclass_name] = x
		close(f)
	end
	x.number_of_docs = size(dir,1)

	#x.number_of_docs = 1
end

###
# Funcion learnFile: Lo mismo que la funcion learn, solo que este recibe una sola direccion del archivo en vez de toda una carpeta
# leer_document se encarga de obtener las palabras y la frecuencia para cada documento
# luego en la funcion add, se añaden las palabras anteriores para dicha clase con las palabras nuevas (x)
###
function learnFile(p::Pool,file::AbstractString,dclass_name::AbstractString)
	x = DocumentClass(Document(p.vocabulario))
	f = open(file)
	d = Document(p.vocabulario)
	#println(file)
	leer_document(d,readall(f),true)
	x.documento = add(x.documento,d)
	x.number_of_docs += 1
	if !haskey(p.clases,dclass_name)
		p.clases[dclass_name] = x
	else
		p.clases[dclass_name] = add(p.clases[dclass_name],x)
	end
	close(f)
	#x.number_of_docs = 1
end

###
# Funcion probabilidad: es la funcion que se encarga de obtener las probabilidades de pertenencia para un documento
# la funcion retorna el primer elemento (La probabilidad mas alta).
# Esta funcion de probabilidad con los argumentos de pool y string (Archivo), itera para todas las clases y pregunta a la funcion de probabilidad
# con 3 argumentos
###
function probabilidad(p::Pool,doc1::AbstractString)
	prob_list = Tuple[]
	for dclass in keys(p.clases)
		#println(dclass)
		prob = probabilidad(p,doc1,dclass)
		push!(prob_list,tuple(dclass,prob))
	end
	sort!(prob_list,by = x->x[2],rev=true)
	#println(prob_list[1])
	return prob_list[1]
end

###
# Funcion de probabilidad: Esta es el nucleo del clasificador bayes ingenuo
# Este implementa la funcion de probabilidad del bayes multinomial (https://en.wikipedia.org/wiki/Naive_Bayes_classifier#Multinomial_naive_Bayes)
# Con eso se evita si una probabilidad es muy cercana a 0, debido a que lleva las probabilidades a un espacio logaritmico 
###
function probabilidad(p::Pool,doc1::AbstractString,dclass::AbstractString)
	#Se obtienen la cantidad total de palabras para dicha clase
	sum_j = sum_words_in_class(p,dclass)
	prob = 0	
	totaldocs = 0
	d = Document(p.vocabulario)
	#Leo el documento
	f = open(doc1)	
	leer_document(d,readall(f),false)
	#Obtengo el total de documentos que existen en cada clase
	for j in keys(p.clases)
		totaldocs += p.clases[j].number_of_docs
	end
	#Inicializo la productoria en 1.
	prod = 1	
	# Calculo la "Productoria" (en el espacio logaritmico, las productorias son sumatorias.)
	for i in palabras(d)
		#Word frequency for documentClass 
		# Se le suma 1 debodp a que log(0) -> indefinido
		wf_dclass = 1 + frecuenciaPalabra(p.clases[dclass],i)
		r = (wf_dclass/sum_j)
		prod += log(r) 
		if prod == 0
			prod = 1*r
		end
	end
	### 
	prob = (prod)+log((p.clases[dclass].number_of_docs / totaldocs))
	if prob != 0
		return (prob)
	else
		return -1
	end
end

###
# Estas funciones de probabilidad, incorporan el argumento debug el cual es una flag para 
# imprimir por pantalla todos los resultados y operaciones para cada iteracion.
###
function probabilidad(p::Pool,doc1::AbstractString,debug::Bool)
	prob_list = Tuple[]
	for dclass in keys(p.clases)
		println(dclass)
		prob = probabilidad(p,doc1,dclass,debug)
		push!(prob_list,tuple(dclass,prob))
	end
	sort!(prob_list,by = x->x[2],rev=true)
	return prob_list[1]
end

function probabilidad(p::Pool,doc1::AbstractString,dclass::AbstractString,debug::Bool)
	sum_dclass = sum_words_in_class(p,dclass)
	prob = 0	
	totaldocs = 0
	d = Document(p.vocabulario)
	f = open(doc1)	
	leer_document(d,readall(f),false)
	println("Palabras"*string(d.palabras_y_freq))
	println(string(keys(p.clases)))
	for j in keys(p.clases)
		totaldocs += p.clases[j].number_of_docs
	end
		sum_j = sum_words_in_class(p,dclass)
		prod = 1
		
		for i in palabras(d)
			wf_dclass = 1 + frecuenciaPalabra(p.clases[dclass],i)
			println(wf_dclass)
			r = (wf_dclass/sum_j)
			prod += log(r) 
			#if prod == 0
		#		prod = 1*r
		#	end
			println(string(i)*"\twf_dclass:"*string(wf_dclass)*"\tr:"*string(r)*" \tprod:"*string(prod))
		end
	prob = (prod) + (log(p.clases[dclass].number_of_docs / totaldocs))
	println(prod)		
	
		println("probabilidad: "*string(prob))
		readline(STDIN)
	if prob != 0
		return (log(prob))
	else
		return -1
	end
end