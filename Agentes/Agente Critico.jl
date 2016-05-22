include("../Tokenizer.jl")

global tabla1 = Tabla()
global tablaAux = Tabla()
global flagHistogram = false
global critval = 0.2
global limTextos = 1000

function parser(s::String)
	texto = replace(s,"\n","")
	return texto

end
function llenar_tabla(conn,ta::Tabla)
	println("Llenar tabla")
	files = getFiles(conn)
	num = length(files)
	ta.files = files
	ta.limTextos = 1000 # cambiar esto
	text2vector(ta,ta.files)
end
function getFiles(conn)
	flag = true
	arr = []
	while flag
		x = readline(conn)
		x = parser(x)
		if x == "Done: give_files"
			flag = false
		else
			push!(arr,x)
		end
	end
	return arr
end
function check_tables(conn,t1::Tabla,t2::Tabla)
	if flagHistogram
		val = dHistogramsWords(t1,t2,0,false)
		crit = val
	else
		val = tTestWords(t1,t2,0,false)
		crit = criticalValue(val)
	end
	println(crit)
	println(critval)
	if crit > critval
		println(conn,"Re-train")
	else
		println(conn,"clasify")
	end
	
end
function add_tables(conn,t1,t2)
	ta = addTablas(t1,tablaAux)
	t1 = ta
	if t1.textos > limTextos 
		println(conn,"limTextos retrain") #Re-entrenamiento con limite de textos
		removeFiles(t1)
		giveNewTrainData(conn,t1.files)
	else
		println(conn,"normal retrain") #Re-entrenamiento sin limite de textos
	end
	return ta
end
function giveNewTrainData(conn,arch::Array)
	for el in arch
		println(conn,el)
	end
	println(conn,"Done: give_new_train_data")
end
function removeFiles(t1::Tabla)
	n = t1.textos - limTextos
	splice!(t1.files,1:n)
	t1.textos = t1.limTextos
end
###
#Servidor creado en el puerto 2002 con una tarea asincrona
###
Task1 = @async begin
         server = listen(2002)
		 t1 = tabla1
		while true
           sock = accept(server)		
           @async while isopen(sock)
			 x = readline(sock)
			 x = parser(x)
			 println(x)
			 if x == "Handshake"
				println(sock,"Handshake")
			 end
			 if x == "Query"
				query = parser(readline(sock))				
				args = parser(readline(sock))
				println("Query: "*query*" with Argument(s): "*args)
				## Definicion de interacciones
				if query == "init"
					dicc = init(args)
				end
				if query == "llenar_tabla"
					if args == "tabla1"
						llenar_tabla(sock,t1)
					end
					if args == "tabla2"
						llenar_tabla(sock,tablaAux)
					end	
				end
				if query == "check_tables"
					check_tables(sock,t1,tablaAux)
				end
				if query == "add_tables"
					t1 = add_tables(sock,t1,tablaAux)
				end
				if query == "debug_dict"
					imprimirDebug(dicc)
				end
				if query == "debug_threshold"
					imprimirDebug(umbral)
				end
				if query == "debug_batch_threshold"
					imprimirDebug(batch_umbral)
				end
				if query == "change_threshold"
					umbral = int(args)
				end
				if query == "change_batch_threshold"
					batch_umbral = int(args)
				end
				if query == "safe_reset"
					## reset variables para benchmarks
					reTrain = String[]
					cont_erroneos = 0
					cont_positivos = 0
					umbral = 70
					batch = 0
					batch_umbral = 0
				end
				
				println(sock,"Done: "*query)
			end
			 ##Revisar esto en algun momento
             if x == "kill"
				println("Killing server")
				println(sock,"killed")
				ex = InterruptException()
				Base.throwto(Task1,ex)
				return false
			 end			 
           end
        end
    end

 