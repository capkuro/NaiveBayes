#function classifier(dirr::String,flagR::Bool,flagRe::Bool,threshold::Int,b_threshold::Int,fl::String,cfg::String)
	include("Estructuras.jl")
	include("util.jl")
	include("Tokenizer.jl")
	p = Pool()
	pools = Pool[]

	#conn = connect(dirr,2001)
	#handshake = false
	Dir = "../textos3/"
	DirCritic = "../docs/twitsTest/"
	DirTest = "../docs/twitsTest"
	flagRand = true
	flagRetrain = true
	DClasses = readdir("../docs/twits")
	function init(po,con,hand,dir,dir2,dir3,flagR,flagRe,dcc)	
		po = Pool()
		con = connect(dirr,2001)
	#	hand = false
		dir = "../docs/twitsLearn/"
		dir2 = "../docs/twitsTest/"
		dir3 = "../docs/twitsTest2"
		flagR = false
		flagRe = false
		dcc = readdir(Dir)
	end
	function resetPools(p1,p2)
		p1 = Pool()
		p2 = Pool[]
	end
	function resetPool()
		p  = Pool()
		pools = Pool[]
	end
	function query(conn,q::String,args::String)
		println(conn,"Query")
		println(conn,q)
		println(conn,args)
	end

	function hs(conn)
		println(conn,"Handshake")
		resp = parser!(readline(conn))
		query(conn,"init",DirCritic)
		println(readline(conn))
		query(conn,"safe_reset","")
		println(readline(conn))
		if resp == "Handshake"
			return true
		end
		return false
	end
	function config_param(threshold,b_threshold)
		#query(conn,"init",DirCritic)
		#println(readline(conn))
		#query(conn,"change_threshold",string(threshold))
		#println(readline(conn))
		#query(conn,"change_batch_threshold",string(b_threshold))
		#println(readline(conn))
	end
	function parser!(s::String)
		texto = replace(s,"\n","")
		return texto

	end
	
	function train()
		for class in DClasses
			learn(p,Dir*class,class)
		end
	end
	#### OCUPAR ESTE
	function train(t::Tabla)
		for file in t.files
			learnFile(p,file,t.indiceT[file])	
		end
	end
	function trainLim(t::Tabla)
		println("Retraining con limite")
		p = Pool()
		for file in t.files
			learnFile(p,file,t.indiceT[file])	
		end
	end
	
	function trainPools(t::Tabla)
		p1 = Pool()
		for file in t.files
			learnFile(p1,file,t.indiceT[file])	
		end
		push!(pools,p1)
	end
	#### HASTA ACA
	
	function train(t::Tabla,limSuperior::Float64)
		n = floor(length(t.files)*limSuperior)
		println(n)
		for file in t.files[1:n]
			
			learnFile(p,file,t.indiceT[file])
		end
	end

	function reTrain(p::Pool,raw_docs::String)
		println("======== RE TRAINING =====")
		## Elimino el formato
		docs = replace(raw_docs,"String","")
		docs = replace(docs,"[","")
		docs = replace(docs,"]","")
		docs = replace(docs,"\"","") #"
		tuplas = split(docs,",")
		println(raw_docs)
		for tupla in tuplas
			doc_cat = split(tupla,";")
			learnFile(p,doc_cat[1],doc_cat[2])
		end

	end

	function reTrain(p::Pool,raw_docs::String,class::String)
		println("======== RE TRAINING =====")
		## Elimino el formato
		docs = replace(raw_docs,"String","")
		docs = replace(docs,"[","")
		docs = replace(docs,"]","")
		docs = replace(docs,"\"","") #"
		tuplas = split(docs,",")
		println(docs)
		for tupla in tuplas
			doc_cat = split(tupla,";")
			learnFile(p,docs,class)
		end

	end

	function test()	
		resultsText = String[]
		resultsAcc = Tuple[]
		class = ""
		j = 0
		for class in DClasses
			files = readdir(DirTest*"/"*class)
			if flagRand
				shuffle!(files)
			end
			for file in files
				res = probabilidad(p,DirTest*"/"*class*"/"*file)
				
				#hola = res[2]
				#if hola <= -40
			#		println("re-entrenando el documento en: "*res[1])
			#		reTrain(p,DirTest*"/"*file,res[1])
		#		end
				push!(resultsText,DirTest*"/"*file*":  "*string(res)*"\n")
				push!(resultsAcc,tuple(class,res[1]))
				println(DirTest*"/"*file*":  "*string(res))
			end
		end
		file = open("./resultados.txt","w")
		for i in resultsText
			write(file,string(i))
		end
		close(file)
		println("resultado de j: "*string(j))
		return resultsAcc	
		
	end

	function test(t::Tabla,arr::Array)
		resultsAcc = Tuple[]
		for el in arr
			res = probabilidad(p,el)
			clase = t.indiceT[el]
			#println(clase*" "string(res))
			push!(resultsAcc,tuple(clase,res[1]))
		end
		return resultsAcc
	end
	function updateWeights(wei::Array, val::Float64)
		valor = val/(1-val)
		#println(valor)
		
		arr = copy(wei)
		arr = arr*valor
		push!(arr,1)
		#println(arr)
		return arr
		
	end
	function testPools(t::Tabla,arr::Array,wei::Array)
		resultsAcc = Tuple[]
		
		for el in arr
			res = Tuple[]
			cats = String[]
			votes = [0.0,0.0,0.0]
			index = 0
			for po in pools
				push!(res,probabilidad(po,el))
			end
			for re in res
				ind = findfirst(res,re)
	
				if re[1] == "Pos"
					votes[1] += 1*wei[ind]
				end
				if re[1] == "Neu"
					votes[2] += 1*wei[ind]
				end
				if re[1] == "Neg"
					votes[3] += 1*wei[ind]
				end
				push!(cats,re[1])
			end
			#println(votes)
			maxi = maximum(votes)
			#println(maxi)
			index = findfirst(votes,maxi)
			#println(index)
			if index == 1
				index = findfirst(cats,"Pos")
			end
			if index == 2
				index = findfirst(cats,"Neu")
			end
			if index == 3
				index = findfirst(cats,"Neg")
			end
			if index == 0
				index = 1
			end
			#res = probabilidad(pools[1],el)
			clase = t.indiceT[el]
			#println(clase*" "string(res))
			#println(index)
			#println(cats)
			x = res[index]
			#println(res)
			
			push!(resultsAcc,tuple(clase,x[1]))
		end
		return resultsAcc
	end
	
	function create_file(results,tCritValues,fl::String,cfg::String,t::Tabla)
		i = 0
		j = 0
		#=
		acq =[0,0,0,0]
		earn =[0,0,0,0]
		trade =[0,0,0,0]
		unkn =[0,0,0,0]
		
		for res in results
			if lowercase(res[2]) == "acq"
				if lowercase(res[1]) == "acq"
					acq[1] += 1
				end
				if lowercase(res[1]) == "earn"
					acq[2] += 1
				end
				if lowercase(res[1]) == "trade"
					acq[3] += 1
				end
				if lowercase(res[1]) == "unknown"
					acq[4] += 1
				end
			end
			if lowercase(res[2]) == "earn"
				if lowercase(res[1]) == "acq"
					earn[1] += 1
				end
				if lowercase(res[1]) == "earn"
					earn[2] += 1
				end
				if lowercase(res[1]) == "trade"
					earn[3] += 1
				end
				if lowercase(res[1]) == "unknown"
					earn[4] += 1
				end
			end
			if lowercase(res[2]) == "trade"
				if lowercase(res[1]) == "acq"
					trade[1] += 1
				end
				if lowercase(res[1]) == "earn"
					trade[2] += 1
				end
				if lowercase(res[1]) == "trade"
					trade[3] += 1
				end
				if lowercase(res[1]) == "unknown"
					trade[4] += 1
				end
			end
			if lowercase(res[2]) == "unknown"
				if lowercase(res[1]) == "acq"
					unkn[1] += 1
				end
				if lowercase(res[1]) == "earn"
					unkn[2] += 1
				end
				if lowercase(res[1]) == "trade"
					unkn[3] += 1
				end
				if lowercase(res[1]) == "unknown"
					unkn[4] += 1
				end
			end
			if lowercase(res[1]) == lowercase(res[2])
				i += 1
			end
			j += 1
		end
		tp = [acq[1], earn[2] , trade[3] , unkn[4]]
		fp = [acq[2] + acq[3] + acq[4] , (earn[1] + earn[3] + earn[4]) , (trade[1] + trade[2] + trade[4]) , (unkn[1] + unkn[2] + unkn[3])]
		fn = [earn[1] + trade[1] + unkn[1] , (acq[2] + trade[2] + unkn[2]) , (acq[3] + earn[3] + unkn[3]) , (acq[4] + earn[4] + trade[4])]
		p1 = tp[1]/(tp[1] + fp[1]); r1 = tp[1]/(tp[1] + fn[1])
		p2 = tp[2]/(tp[2] + fp[2]); r2 = tp[2]/(tp[2] + fn[2])
		p3 = tp[3]/(tp[3] + fp[3]); r3 = tp[3]/(tp[3] + fn[3])
		p4 = tp[4]/(tp[4] + fp[4]); r4 = tp[4]/(tp[4] + fn[4])
		file = open(fl,"w")
		
		println(file,cfg)
		println(file,"Accuracy: "*string(i*100/j))
		
		prec = (tp[1] + tp[2] + tp[3] + tp[4])/((tp[1] + tp[2] + tp[3] + tp[4])+(fp[1] + fp[2] + fp[3] + fp[4]))
		recc = (tp[1] + tp[2] + tp[3] + tp[4])/((tp[1] + tp[2] + tp[3] + tp[4])+(fn[1] + fn[2] + fn[3] + fn[4]))
	
		precM = (p1+p2+p3+p4)/4
		reccM = (r1+r2+r3+p4)/4
		f1M = (2*precM*reccM)/(precM+reccM)
		f1 = (2*prec*recc)/(prec+recc)
		println(file,"$acq")
		println(file,"$earn")
		println(file,"$trade")
		println(file,"$unkn")
		println(file,"micro prec: $prec recc: $recc f1: $f1")
		println(file,"macro prec: $precM recc: $reccM f1: $f1M")
		
		=#
		##Comentado para tweets
		
		pos =[0,0,0]
		neg =[0,0,0]
		neu =[0,0,0]
		#println("IMPRIMO RES"*string(results))
		for res in results
			if res[2] == "Pos"
				if lowercase(res[1]) == "pos"
					pos[1] += 1
				end
				if lowercase(res[1]) == "neg"
					pos[2] += 1
				end
				if lowercase(res[1]) == "neu"
					pos[3] += 1
				end
			end
			if res[2] == "Neg"
				if lowercase(res[1]) == "pos"
					neg[1] += 1
				end
				if lowercase(res[1]) == "neg"
					neg[2] += 1
				end
				if lowercase(res[1]) == "neu"
					neg[3] += 1
				end
			end
			if res[2] == "Neu"
				if lowercase(res[1]) == "pos"
					neu[1] += 1
				end
				if lowercase(res[1]) == "neg"
					neu[2] += 1
				end
				if lowercase(res[1]) == "neu"
					neu[3] += 1
				end
			end
			if lowercase(res[1]) == lowercase(res[2])
				i += 1
			end
			j += 1
		end
		tp = [pos[1], neg[2],neu[3]]
		fp = [pos[2] + pos[3] , (neg[1] + neg[3]) , (neu[1] + neu[2])]
		fn = [neg[1] + neu[1] , (pos[2] + neu[2]) , (pos[3] + neg[3])]
		p1 = tp[1]/(tp[1] + fp[1]); r1 = tp[1]/(tp[1] + fn[1])
		p2 = tp[2]/(tp[2] + fp[2]); r2 = tp[2]/(tp[2] + fn[2])
		p3 = tp[3]/(tp[3] + fp[3]); r3 = tp[3]/(tp[3] + fn[3])
		file = open(fl,"w")
		if isnan(p1)
			p1 = 0
		end
		if isnan(p2)
			p2 = 0
		end
		if isnan(p3)
			p3 = 0
		end
		if isnan(r1)
			r1 = 0
		end
		if isnan(r2)
			r2 = 0
		end
		if isnan(r3)
			r3 = 0
		end
		println(file,cfg)		
		prec = (tp[1] + tp[2] + tp[3])/((tp[1] + tp[2] + tp[3])+(fp[1] + fp[2] + fp[3]))
		recc = (tp[1] + tp[2] + tp[3])/((tp[1] + tp[2] + tp[3])+(fn[1] + fn[2] + fn[3]))
		
		precM = (p1+p2+p3)/3
		reccM = (r1+r2+r3)/3
		f1M = (2*precM*reccM)/(precM+reccM)
		f1 = (2*prec*recc)/(prec+recc)
		
		println(file,"Accuracy: "*string(i/j))
		println(file,"macro prec: $precM ")
		println(file,"recc: $reccM ")
		println(file,"f1: $f1M")
		println(file,"tCritValues: $tCritValues")
		
		lim1 = t.limSuperior
		lim2 = t.limInferior
		porcentaje = t.porcentaje
		println(file,"Limite superior de los datos: $lim1 limite inferior:$lim2. Porcentaje del palabras que no estan distribuidas normal:$porcentaje")
		close(file)
		return f1M
	end
	
	#handshake = hs(conn)
	#config_param(threshold,b_threshold)
	#t = initT(Dir,threshold,flagR)
	#train(t,t.limSuperior)
	#train()
	
	#res = test()
	#create_file(res,fl,cfg,t)
	
#end