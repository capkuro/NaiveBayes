include("../Main.jl")
global p = Pool()
global pools = Pool[]
global ta = Tabla()
arch = []

function parser(s::String)
	texto = replace(s,"\n","")
	return texto

end
function getElements(conn)
	flag = true
	arr = []
	println(conn,"Query")
	println(conn,"give_elements")
	println(conn,"none") #sin argumentos
	while flag
		x = readline(conn)
		x = parser(x)
		if x == "Done: give_elements"
			flag = false
		else
			push!(arr,x)
		end
	end
	return arr
end
function getNewTrainData(conn)
	flag = true
	arr = []
	while flag
		x = readline(conn)
		x = parser(x)
		if x == "Done: give_new_train_data"
			flag = false
		else
			push!(arr,x)
		end
	end
	return arr
end
function giveElements(conn,arch::Array,args::String)
	println(conn,"Query")
	println(conn,"llenar_tabla")
	println(conn,args) #sin argumentos
	for el in arch
		println(conn,el)
	end
	println(conn,"Done: give_files")
	println(parser(readline(conn)))
end
function train(conn,arch::Array)

	for file in arch
		println(conn,"Query")
		println(conn,"get_doc_class")
		println(conn,file)
		class = parser(readline(conn))		
		(readline(conn)) ## done get_doc_class
		learnFile(p,file,class)	
	end
	
end
function trainLim(conn,arch::Array)
	newPool = Pool()
	p.clases = newPool.clases
	p.vocabulario = newPool.vocabulario
	for file in arch
		println(conn,"Query")
		println(conn,"get_doc_class")
		println(conn,file)
		class = parser(readline(conn))		
		(readline(conn)) ## done get_doc_class
		learnFile(p,file,class)	
	end
	po = p
	
end

function test(conn,arch::Array)
	resultsAcc = Tuple[]
	for file in arch
		println(conn,"Query")
		println(conn,"get_doc_class")
		println(conn,file)
		class = parser(readline(conn))		
		(readline(conn)) ## done get_doc_class
		res = probabilidad(p,file)	
		push!(resultsAcc,tuple(class,res[1]))
	end
	return resultsAcc
	
end
# Genero la conexion con el agente distribuidor (Puerto 2001) y el agente critico (Puerto 2002)

connDist = connect("localhost",2001)
connCrit = connect("localhost",2002)
println(connDist,"Handshake")
x = parser(readline(connDist))
println(x)

println(connCrit,"Handshake")
x = parser(readline(connCrit))
println(x)

### Esta es la primera iteración
arch = getElements(connDist)
archTrain = arch[1:floor(length(arch)*0.7)] #70% para training
archTest = arch[floor(length(arch)*0.7)+1:floor(length(arch))] #30% para testing
giveElements(connCrit,archTrain,"tabla1")
train(connDist,archTrain)
res = test(connDist,archTest)

for i in 1:9
	arch = getElements(connDist)
	archTrain = arch[1:floor(length(arch)*0.7)] #70% para training
	archTest = arch[floor(length(arch)*0.7)+1:length(arch)] #30% para testing
	giveElements(connCrit,arch,"tabla2")
	println(connCrit,"Query")
	println(connCrit,"check_tables") #query
	println(connCrit,"none") #arguments
	resp = parser(readline(connCrit))
	println(resp)
	println(parser(readline(connCrit))) #done check_tables
	if resp =="Re-train"
		println("Re-training")
		giveElements(connCrit,archTrain,"tabla2")
		
		println(connCrit,"Query")
		println(connCrit,"add_tables") # query
		println(connCrit,"none") # Arguments
		retrainMsg = parser(readline(connCrit)) #Tipo de retraining
		
		if retrainMsg == "limTextos retrain"
			archTrain = getNewTrainData(connCrit)
			trainLim(connDist,archTrain)
		end
		if retrainMsg == "normal retrain"
			train(connDist,archTrain)
		end	
		println(parser(readline(connCrit))) # #done add_tables
		n = 0
		for key in keys(p.clases)
			n += p.clases[key].number_of_docs
		end
		print("cant: ")
		println(n)
	end
	
	res = test(connDist,archTest)
	println(res)
end
