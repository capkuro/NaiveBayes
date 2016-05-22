function classifier(dirr::String,flagR::Bool,flagRe::Bool,threshold::Int,b_threshold::Int,fl::String,cfg::String)
	include("Estructuras.jl")
	include("util.jl")


	p = Pool()
	conn = connect(dirr,2001)
	handshake = false
	Dir = "./docs/twitsLearn/"
	DirCritic = "./docs/twitsTest/"
	DirTest = "./docs/twitsTest2"
	flagRand = flagR
	flagRetrain = flagRe
	DClasses = readdir(Dir)

	function init(po,con,hand,dir,dir2,dir3,flagR,flagRe,dcc)	
		po = Pool()
		con = connect(dirr,2001)
		hand = false
		dir = "./docs/twitsLearn/"
		dir2 = "./docs/twitsTest/"
		dir3 = "./docs/twitsTest2"
		flagR = false
		flagRe = false
		dcc = readdir(Dir)
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
		query(conn,"init",DirCritic)
		println(readline(conn))
		query(conn,"change_threshold",string(threshold))
		println(readline(conn))
		query(conn,"change_batch_threshold",string(b_threshold))
		println(readline(conn))
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

	function reTrain(p::Pool,raw_docs::String)
		println("======== RE TRAINING =====")
		## Elimino el formato
		docs = replace(raw_docs,"String","")
		docs = replace(docs,"[","")
		docs = replace(docs,"]","")
		docs = replace(docs,"\"","") #"
		tuplas = split(docs,",")
		for tupla in tuplas
			doc_cat = split(tupla,";")
			learnFile(p,doc_cat[1],doc_cat[2])
		end

	end



	function test()	
		resultsText = String[]
		resultsAcc = Tuple[]
		class = ""
		j = 0
		##for class in DClasses
		files = readdir(DirTest)
		if flagRand
			shuffle!(files)
		end
			for file in files
				res = probabilidad(p,DirTest*"/"*file)
				
				if handshake && flagRetrain
					query(conn,"check_doc",file*","*res[1])
					resp = parser!(readline(conn))
					if resp == "doc_class_false"
						class = parser!(readline(conn))
						println(conn,DirTest*"/"*file)
						accion = parser!(readline(conn))
						if accion == "retrain_docs"
							docs = parser!(readline(conn))
							reTrain(p,docs)
						end
					else
						class = res[1]
					end
					readline(conn)
					##write(STDOUT,readline(conn))
				else
					query(conn,"get_doc_class",file)
					class = parser!(readline(conn))
					readline(conn)
				end
				
				push!(resultsText,DirTest*"/"*file*":  "*string(res)*"\n")
				push!(resultsAcc,tuple(class,res[1]))
				println(DirTest*"/"*file*":  "*string(res))
			end
		##end
		file = open("./resultados.txt","w")
		for i in resultsText
			write(file,string(i))
		end
		close(file)
		println("resultado de j: "*string(j))
		return resultsAcc	
		
	end

	function create_file(results,fl::String,cfg::String)
		i = 0
		j = 0
		pos =[0,0,0]
		neg =[0,0,0]
		neu =[0,0,0]
		
		for res in results
			if res[2] == "Pos"
				if res[1] == "Pos"
					pos[1] += 1
				end
				if res[1] == "Neg"
					pos[2] += 1
				end
				if res[1] == "Neu"
					pos[3] += 1
				end
			end
			if res[2] == "Neg"
				if res[1] == "Pos"
					neg[1] += 1
				end
				if res[1] == "Neg"
					neg[2] += 1
				end
				if res[1] == "Neu"
					neg[3] += 1
				end
			end
			if res[2] == "Neu"
				if res[1] == "Pos"
					neu[1] += 1
				end
				if res[1] == "Neg"
					neu[2] += 1
				end
				if res[1] == "Neu"
					neu[3] += 1
				end
			end
			if res[1] == res[2]
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
		
		println(file,cfg)
		println(file,"Accuracy: "*string(i*100/j))
		
		prec = (tp[1] + tp[2] + tp[3])/((tp[1] + tp[2] + tp[3])+(fp[1] + fp[2] + fp[3]))
		recc = (tp[1] + tp[2] + tp[3])/((tp[1] + tp[2] + tp[3])+(fn[1] + fn[2] + fn[3]))
		precM = (p1+p2+p3)/3
		reccM = (r1+r2+r3)/3
		f1M = (2*precM*reccM)/(precM+reccM)
		f1 = (2*prec*recc)/(prec+recc)
		println(file,"$pos")
		println(file,"$neg")
		println(file,"$neu")
		println(file,"micro prec: $prec recc: $recc f1: $f1")
		println(file,"macro prec: $precM recc: $reccM f1: $f1M")
		close(file)
	end
	
	handshake = hs(conn)
	config_param(threshold,b_threshold)
	train()
	res = test()
	create_file(res,fl,cfg)
	
end