include("../estructuras.jl")


dir = "./docs/twits"
global ta = Tabla()
ta.categorias = readdir(dir)
	Archivos = Dict()
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

function giveElements(n::Int)
	numberElements = int(floor(n/length(ta.categorias)))
	f = []
	
	for cate in ta.categorias
		arch = splice!(Archivos[cate],1:numberElements)
		f = cat(1,f,arch)
	end	
	return f
end

function giveElements(n::Int,flag::Bool)
	Arch = ta.files
	if flag
		f = splice!(Arch,1:n)
		#println(f)
		return f
	else
		return giveElements(n)
	end
end

function giveElements(sock,n::Int,flag::Bool)
	Arch = ta.files
	shuffle!(Arch)
	if flag
		f = splice!(Arch,1:n)
		#println(f)
		println(length(Arch))
		for el in f
			println(el)
			println(sock,el)
		end
	else
		return giveElements(n)
	end
end

function get_doc_class(args::String)
	
	indicesT = ta.indiceT
	if haskey(indicesT,args)
		return indicesT[args]
	end
	return "none"
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
###
#Conexion entre el Agente Distribuidor y el Agente clasificador
###
Task1 = @async begin
         server = listen(2001)
		 dicc  = Dict()  ## Diccionario de documentos con sus clases
		while true
           sock = accept(server)
		   sk = sock
		
           @async while isopen(sock)
			 x = readline(sock)
			 x = parser!(x)
			 println(x)
			 if x == "Handshake"
				println(sock,"Handshake")
			 end
			 if x == "Query"
				query = parser!(readline(sock))
				
				args = parser!(readline(sock))
				println("Query: "*query*" with Argument(s): "*args)
				## Definicion de interacciones
				if query == "init"
					dicc = init(args)
				end
				if query == "give_elements"
					giveElements(sock,300,true)
				end
				if query == "get_doc_class"
					class = get_doc_class(args)
						## envio la clase
					println(sock,class)
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

###
#Conexion entre el Agente Distribuidor y el Agente critico
###
