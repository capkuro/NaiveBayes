# Definición de estructuras basicas para el funcionamiento de la estructura.
include("util.jl")

##Tabla y sus metodos
abstract tabla
### Tabla es la estructura que contiene todos los elementos para el calculo
type Tabla <: tabla
	Diccionario::Dict
	indiceT::Dict ##Indice de los textos
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

function Tabla()
	table = Tabla(Dict(),Dict(),[0],[0],[0],[0],[0],[0],[0],0,0,0,0,0,0)
	return table
end
function Add_word(table::tabla,word::String)
	if !haskey(table.t,word)
		table.numeroPalabras += 1
		table.t[word] = table.numeroPalabras
	end
end
##BagOfWords y sus metodos
abstract bagOfWords

type BagOfWords <: bagOfWords
	NumeroPalabras::Int
	Bag_of_words::Dict
end

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
function add_word(bag::bagOfWords,word::String)
	bag.NumeroPalabras +=1
	if haskey(bag.Bag_of_words,word)
		bag.Bag_of_words[word] += 1
	else
		bag.Bag_of_words[word] = 1
	end
end
#function length(bag::bagOfWords)
#	return size([key for key in keys(bag.Bag_of_words)],1)
#end
function palabras(bag::bagOfWords)
	return keys(bag.Bag_of_words)
end
function bolsa(bag::bagOfWords)
	return bag.Bag_of_words
end

function frecuenciaPalabra(bag::bagOfWords,word::String)
	if haskey(bag.Bag_of_words,word)
		return bag.Bag_of_words[word]
	else
		return 0
	end
end


## Document y sus metodos

abstract Doc

type Document <: Doc
	nombre::String
	clase::String
	palabras_y_freq::BagOfWords
	vocabulario::BagOfWords
end

##Añadir constructor con vocabulario para entrenamiento
function Document()
	doc = Document("","",BagOfWords(),BagOfWords())
	return doc
end

function Document(vocab::BagOfWords)
	doc = Document("","",BagOfWords(),vocab)
	return doc
end

function add(doc1::Document, doc2::Document)
	res = Document()
	res.vocabulario = doc1.vocabulario
	res.palabras_y_freq = add(doc1.palabras_y_freq,doc2.palabras_y_freq)
	return res
end

function and(doc1::Document, doc2::Document) ## Interseccion
	interseccion = String[]
	keys1 = palabras(doc1)
	for word in palabras(doc2)
		if word in keys1
			push!(interseccion,word)
		end
	end
	return interseccion	
end
function leer_document(doc::Document,texto::String, aprender::Bool)
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

function tamano_vocabulario(doc::Document)
	return length(doc.vocabulario)
end

function palabrasYFreq(doc::Document)
	return bolsa(doc.palabras_y_freq)
end

function palabras(doc::Document)
	bag = bolsa(doc.palabras_y_freq)
	return keys(bag)
end

function frecuenciaPalabra(doc::Document,word::String)
	bag = bolsa(doc.palabras_y_freq)
	if haskey(bag,word)
		return bag[word]
	else
		return 0
	end
end

##
abstract documentClass

type DocumentClass <: documentClass
	documento::Document
	number_of_docs::Int
end

function DocumentClass()
	DC = DocumentClass(Document(),0)
	return DC
end
function DocumentClass(doc::Document)
	DC = DocumentClass(doc,0)
	return DC
end
function probabilidad(dc::DocumentClass,word::String)
	voc_len = tamano_vocabulario(dc.documento)
	
	#for i in range(voc_len)
	SumN = frecuenciaPalabra(dc.documento.vocabulario,word)
	#end
	N = frecuenciaPalabra(dc.documento,word)
	
	erg =  N / (voc_len + SumN)
	return erg
end

function add(dc1::DocumentClass,dc2::DocumentClass)
	res = DocumentClass()
	res.documento = add(dc1.documento,dc2.documento)
	res.number_of_docs = dc1.number_of_docs + dc2.number_of_docs
	return res
end
function palabrasYFreq(dc1::DocumentClass)
	return palabrasYFreq(dc1.documento)
end
##

function frecuenciaPalabra(doc::DocumentClass,word::String)
	return frecuenciaPalabra(doc.documento,word)
end
### Pool y sus metodos
### pool es la encargada de manejar la bolsa de palabras para el bayes ingenuo

abstract pool
type Pool <: pool
	clases:: Dict
	vocabulario::BagOfWords
end

function Pool()
	p = Pool(Dict(),BagOfWords())
	return p
end

##

function sum_words_in_class(p::Pool,dclass::String)
	sum = 0
	for word in palabras(p.vocabulario)
		WaF = palabrasYFreq(p.clases[dclass])
		if haskey(WaF,word)
			sum += WaF[word]
		end
	end
	return sum
end

function learn(p::Pool,directory::String,dclass_name::String)
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

function learnFile(p::Pool,file::String,dclass_name::String)
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

function probabilidad(p::Pool,doc1::String)
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

function probabilidad(p::Pool,doc1::String,dclass::String)
	sum_dclass = sum_words_in_class(p,dclass)
	prob = 0	
	totaldocs = 0
	d = Document(p.vocabulario)
	f = open(doc1)	
	leer_document(d,readall(f),false)
	#println("Palabras"*string(d.palabras_y_freq))
	#println(string(keys(p.clases)))
	for j in keys(p.clases)
		totaldocs += p.clases[j].number_of_docs
	end
		sum_j = sum_words_in_class(p,dclass)
		prod = 1
		
		for i in palabras(d)
			wf_dclass = 1 + frecuenciaPalabra(p.clases[dclass],i)
			#println(wf_dclass)
			r = (wf_dclass/sum_j)
			prod += log(r) 
			if prod == 0
				prod = 1*r
			end
			#println(string(i)*"\twf_dclass:"*string(wf_dclass)*" \twf:"*string(wf)*" \tr:"*string(r)*" \tprod:"*string(prod))
		end
	prob = (prod)+log((p.clases[dclass].number_of_docs / totaldocs))
	#println(prod)		
	
		#println("probabilidad: "*string(prob))
		#readline(STDIN)
	if prob != 0
		return (prob)
	else
		return -1
	end
end

function probabilidad(p::Pool,doc1::String,debug::Bool)
	prob_list = Tuple[]
	for dclass in keys(p.clases)
		println(dclass)
		prob = probabilidad(p,doc1,dclass,debug)
		push!(prob_list,tuple(dclass,prob))
	end
	sort!(prob_list,by = x->x[2],rev=true)
	return prob_list[1]
end

function probabilidad(p::Pool,doc1::String,dclass::String,debug::Bool)
	sum_dclass = sum_words_in_class(p,dclass)
	prob = 0	
	totaldocs = 0
	d = Document(p.vocabulario)
	f = open(doc1)	
	leer_document(d,readall(f),false)
	#println("Palabras"*string(d.palabras_y_freq))
	#println(string(keys(p.clases)))
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
	#println(prod)		
	
		println("probabilidad: "*string(prob))
		readline(STDIN)
	if prob != 0
		return (log(prob))
	else
		return -1
	end
end