#include("critico.jl")

include("main.jl")


batch = [10,20]

umbral = [70]

flags = [true]
i = 0
println("Inserte IP del server")
ip = readline(STDIN)
ip = replace(ip,"\r","")
ip = replace(ip,"\n","")
for bt in batch
	for um in umbral
		for fl in flags
			if fl
				for j  in 1:3
					config = "reTrain true - shuffle $fl - umbral $um - batch $bt - run $j"
					println(config)
					classi = classi = classifier(ip,fl,true,um,bt,"./benchmarkResult/"*config*".txt",config)
				end
			else
				config = "reTrain true - shuffle $fl umbral $um - batch $bt"
				println(config)
				classi = classi = classifier(ip,fl,true,um,bt,"./benchmarkResult/"*config*".txt",config)
			end
		end	
	end
	i += 1
end
