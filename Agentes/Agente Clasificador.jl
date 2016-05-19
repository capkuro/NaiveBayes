function init(dir::String)
	dicc = Dict()
	DClasses = readdir(dir)
	for class in DClasses
		docs = readdir(dir*"/"*class)
		dicc[class] = docs
	end
	return dicc
	println("done init")
end

function imprimirDebug(foo)
	println(string(foo))
end

function parser!(s::String)
	texto = replace(s,"\n","")
	return texto

end
y=0
function sum()
	global y = y + 1
end
function printY()
	return y
end
Task1 = @async begin
         server = listen(2001)
		 dicc  = Dict()  ## Diccionario de documentos con sus clases
		 reTrain = String[]
		 cont_erroneos = 0
		 cont_positivos = 0
		 umbral = 70 ## default
		 batch = 0
		 batch_umbral = 0 ## default
		 sockets = []
		 println(y)
		while true
           sock = accept(server)
		   push!(sockets,sock)
		   sk = sock
		
           @async while isopen(sock)
			 x = readline(sock)
			 x = parser!(x)
			 println(x)
			 if x == "Handshake"
				println(sock,"Handshake")
			 end
			 if x == "sum"
				sum()
			 end
			 if x == "printY"
				println(sock,printY())
			 end
			 if x == "Query"
				query = parser!(readline(sock))
				
				args = parser!(readline(sock))
				println("Query: "*query*" with Argument(s): "*args)
				## Definicion de interacciones
				if query == "init"
					dicc = init(args)
				end
				if query == "get_doc_class"
				class = get_doc_class(dicc,args)
						## envio la clase
						println(sock,class)
				end
				if query == "check_certainty"
				check = certainty(args)
				end
				if query == "check_doc"
					check = check_doc(dicc,args)
					if check
						println(sock,"doc_class_true")
						cont_positivos +=1
						
					else
						##Aviso que esta errada la clasificacion
						println(sock,"doc_class_false")
						##obtengo la clase verdadera
						class = get_doc_class(dicc,args)
						## envio la clase
						println(sock,class)
						##obtengo la direccion
						dir = parser!(readline(sock))
						push!(reTrain,dir*";"*class)
						cont_erroneos += 1
						batch += 1
						acc = (cont_positivos/(cont_erroneos+cont_positivos)*100)
						if acc <= umbral && (cont_positivos + cont_erroneos) > 10 && (batch >= batch_umbral)
							println("Accuracy clasificador: $acc % vs $umbral %" )
							println(sock, "retrain_docs")
							println(sock, reTrain)
							reTrain = String[]
							batch = 0
						else
							println(sock,"feed")
						end
					end
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

 