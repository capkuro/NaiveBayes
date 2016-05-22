# NaiveBayes
#Tesis

Datasets
---
Se presentan los dataset en la carpeta docs (pa agentes y la version que considera los agentes como objetos)
- twits.rar: conjunto de twits vinculados al problema de análisis de sentimiento con respecto a distintas multitiendas.
- reuters.rar: Conjunto de textos recopilados por reuters. ese es un subconjunto del conjunto de reuters 21578 (http://www.daviddlewis.com/resources/testcollections/reuters21578/)

Agentes
---
La carpeta agentes contiene la implementación de los agentes como servidores, utilizando los sockets tcp/ip:
- Agente clasificador se conecta hacia agente critico y agente distribuidor
- Agente Critico: Servidor que utiliza el puerto 2002 y cumple las funciones descritas (tanto t-test como diferencia de histogramas)
- Agente Distribuidor: Servidor que utiliza el puero 2001 y cumple las funciones de distribuir tanto los textos al agente clasificador, como obtener la verdadera categoria para un texto.

Funciones implementadas:
---

- benchmark.jl: implementa varias instancias del clasificador y critico con distintas configuraciones para realizar las pruebas de cual es la mejor configuración posible.

- Main.jl
```
	- function init(po,con,hand,dir,dir2,dir3,flagR,flagRe,dcc)
	- function resetPools(p1,p2)
	- function resetPool()
	- function query(conn,q::AbstractString,args::AbstractString)
	- function hs(conn)
	- function config_param(threshold,b_threshold)
	- function parser!(s::AbstractString)
	- function train(t::Tabla)
	- function trainLim(t::Tabla)
	- function trainPools(t::Tabla)
	- function train(t::Tabla,limSuperior::Float64)
	- function test(t::Tabla,arr::Array)
	- function updateWeights(wei::Array, val::Float64)
	- function testPools(t::Tabla,arr::Array,wei::Array)
	- function create_file(results,tCritValues,fl::AbstractString,cfg::AbstractString,t::Tabla)
```

- Distribuidor.jl
 ```
	function giveElements(n::Int)
 	function giveElements(n::Int,flag::Bool,Arch::Array)
    function bench(flagH::Bool,flagP::Bool,flagTI::Bool,li::Int,sep::Int,numRank::Int,spVal::Float64,crVal::Float64,ite::Int)
 ```
- Tokenizer.jl
```
	function initT(dir::AbstractString)
    function initT(bool::Bool,ta::Tabla,num::Int,limT::Int,Arch::Array)
	function fileHistogram(Hist::Array,dir::AbstractString,iteracion)
    function tokenizer(Diccionario::Dict,texto::AbstractString)
    function textsInput(Arr::Array)
    function text2vector(t::Tabla,Arr::Array)
    function updateVector!(vector::Array,Dicc::Dict,Arr::Array)
    function updateMeanStd(t::Tabla)
    function tTestWords(t1::Tabla,t2::Tabla,numRanking::Int,tfIdf::Bool)
    function dHistogramsWords(t1::Tabla,t2::Tabla,numRanking::Int,tfIdf::Bool)
    function criticalValue(Arr::Array)
    function varianceTest(t::Tabla,n1::Float64,n2::Float64)
    function updateVariance!(t::Tabla,n1::Float64,n2::Float64)
    function tTest2(t::Tabla,n1::Float64,n2::Float64)
    function toTuple(t::Tabla)
    function rankingTfIdf(Diccionario::Dict,tfIdf::Array,indice::Int)
    function updateDiccWithRanking!(t::Tabla,indice::Int)
    function updateDiccWithRanking!(t::Tabla,indice::Int,bool::Bool)
    function idf(ar::Array)
    function tfidf(t::Tabla)
    function histogram(t::Tabla,n1::Int,n2::Int)
    function histogram(t::Tabla,n1::Float64,Bottom::Bool,indice::Int)
    function ranking(t::Tabla,indice::Int)
    function histogram2(t::Tabla,n1::Float64,Bottom::Bool,indice::Int)
    function ranking2(t::Tabla,indice::Int)
    function histogramWithoutRanking(t::Tabla,n1::Float64,Bottom::Bool)
    function distHistogram(Arr1::Array,Arr2::Array)
    function distHistogram(Arr1::Array,Arr2::Array,tipo::Int)
```
- Estructura.jl
```
	type Tabla <: tabla
    type BagOfWords <: bagOfWords
    type Document <: Doc
    type DocumentClass <: documentClass
    type Pool <: pool
    function Tabla()
    function splitTrainTest(t::Tabla,limSuperior::Float64)
    function Add_word(table::tabla,word::AbstractString)
    function addTablas(t1::Tabla,t2::Tabla)
    function removeFiles(t1::Tabla)
    function add(bag1::bagOfWords,bag2::bagOfWords)
    function add_word(bag::bagOfWords,word::AbstractString)
    function palabras(bag::bagOfWords)
    function bolsa(bag::bagOfWords)
    function frecuenciaPalabra(bag::bagOfWords,word::AbstractString)
    function Document()
    function Document(vocab::BagOfWords)
    function add(doc1::Document, doc2::Document)
    function and(doc1::Document, doc2::Document)
    function leer_document(doc::Document,texto::AbstractString, aprender::Bool)
    function tamano_vocabulario(doc::Document)
    function palabrasYFreq(doc::Document)
    function palabras(doc::Document)
    function frecuenciaPalabra(doc::Document,word::AbstractString)
    function DocumentClass()
    function DocumentClass(doc::Document)
    function probabilidad(dc::DocumentClass,word::AbstractString)
    function add(dc1::DocumentClass,dc2::DocumentClass)
    function palabrasYFreq(dc1::DocumentClass)
    function frecuenciaPalabra(doc::DocumentClass,word::AbstractString)
    function Pool()
    function sum_words_in_class(p::Pool,dclass::AbstractString)
    function learn(p::Pool,directory::AbstractString,dclass_name::AbstractString)
    function learnFile(p::Pool,file::AbstractString,dclass_name::AbstractString)
    function probabilidad(p::Pool,doc1::AbstractString)
    function probabilidad(p::Pool,doc1::AbstractString,dclass::AbstractString)
    function probabilidad(p::Pool,doc1::AbstractString,debug::Bool)
    function probabilidad(p::Pool,doc1::AbstractString,dclass::AbstractString,debug::Bool)
```
- util.jl
```
	function estandarizar(texto)
    removerNumeros(texto)
    removerStopWords(texto)
```

No Aplica
---
Carpeta con iteraciones anteriores al codigo final.

Instrucciones
---
Para hacer funcionar el codigo en la version de objetos, abrir benchmark.jl teniendo descomprimido twits en la carpeta docs. (para hacer funcionar reuters, hay que manipular las rutas predefinidas en los codigos, al igual que las metricas (en main.jl))

para hacer funcionar el codigo con la version de agentes, abrir el agente distribuidor y critico, para luego abrir el agente clasificador, al igual que la version de objetos, hay que tener descomprimidos los datasets en la carpeta docs, para luego editar en el agente distribuidor, la ruta de los textos.
