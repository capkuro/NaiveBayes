function parser(dir)
	docs = readdir(dir)
	titles = docs[2:13]
	deleteat!(docs,1:13)
	
	
	for title in titles
		nt = replace(title,"false","true -")
		fl = open(dir*"/parsed/"*nt,"w")
		acu = Float64[]
		mP = Float64[]
		mR = Float64[]
		mF = Float64[]
		MP = Float64[]
		MR = Float64[]
		MF = Float64[]
		for i in 1:10	
			f = open(dir*"/"*replace(nt,".txt"," - run $i.txt"))
			tit = readline(f)
			acc = replace(readline(f),"Accuracy:","")
			readline(f);readline(f);readline(f)
			line = readline(f); line = replace(line,"micro prec:",""); line = replace(line,"recc:","") ; line = replace(line,"f1:","")
			micro = split(line)
			line = readline(f); line = replace(line,"macro prec:",""); line = replace(line,"recc:","") ; line = replace(line,"f1:","")
			macc = split(line)
			
			push!(acu,float(micro[1]))
			push!(mP,float(micro[1]))
			push!(mR,float(micro[2]))
			push!(MP,float(macc[1]))
			push!(MR,float(macc[2]))
			push!(mF,float(micro[3]))
			push!(MF,float(macc[3]))
			close(f)
		end
		
		println(fl,replace(replace(string(acu),"[",""),"]",""))
		println(fl,replace(replace(string(mP),"[",""),"]",""))
		println(fl,replace(replace(string(mR),"[",""),"]",""))
		println(fl,replace(replace(string(MP),"[",""),"]",""))
		println(fl,replace(replace(string(MR),"[",""),"]",""))
		println(fl,replace(replace(string(mF),"[",""),"]",""))
		println(fl,replace(replace(string(MF),"[",""),"]",""))
		
		close(fl)
	end
	
	
end