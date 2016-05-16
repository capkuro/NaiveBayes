stopwords = ["a, acuerdo"," adelante"," ademas"," además"," adrede"," ahi"," ahí"," ahora"," al"," alli"," allí"," alrededor"," antano"," antaño"," ante"," antes"," apenas"," aproximadamente"," aquel"," aquél"," aquella"," aquélla"," aquellas"," aquéllas"," aquello"," aquellos"," aquéllos"," aqui"," aquí"," arriba"," abajo"," asi"," así"," aun"," aún"," aunque"," b"," bajo"," bastante"," bien"," breve"," c"," casi"," cerca"," claro"," como"," cómo"," con"," conmigo"," contigo"," contra"," cual"," cuál"," cuales"," cuáles"," cuando"," cuándo"," cuanta"," cuánta"," cuantas"," cuántas"," cuanto"," cuánto"," cuantos"," cuántos"," d"," de"," debajo"," del"," delante"," demasiado"," dentro"," deprisa"," desde"," despacio"," despues"," después"," detras"," detrás"," dia"," día"," dias"," días"," donde"," dónde"," dos"," durante"," e"," el"," él"," ella"," ellas"," ellos"," en"," encima"," enfrente"," enseguida"," entre"," es"," esa"," ésa"," esas"," ésas"," ese"," ése"," eso"," esos"," ésos"," esta"," está"," ésta"," estado"," estados"," estan"," están"," estar"," estas"," éstas"," este"," éste"," esto"," estos"," éstos"," ex"," excepto"," f"," final"," fue"," fuera"," fueron"," g"," general"," gran"," h"," ha"," habia"," había"," habla"," hablan"," hace"," hacia"," han"," hasta"," hay"," horas"," hoy"," i"," incluso"," informo"," informó"," j"," junto"," k"," l"," la"," lado"," las"," le"," lejos"," lo"," los"," luego"," m"," mal"," mas"," más"," mayor"," me"," medio"," mejor"," menos"," menudo"," mi"," mí"," mia"," mía"," mias"," mías"," mientras"," mio"," mío"," mios"," míos"," mis"," mismo"," mucho"," muy"," n"," nada"," nadie"," ninguna"," no"," nos"," nosotras"," nosotros"," nuestra"," nuestras"," nuestro"," nuestros"," nueva"," nuevo"," nunca"," o"," os"," otra"," otros"," p"," pais"," paìs"," para"," parte"," pasado"," peor"," pero"," poco"," por"," porque"," pronto"," proximo"," próximo"," puede"," q"," qeu"," que"," qué"," quien"," quién"," quienes"," quiénes"," quiza"," quizá"," quizas"," quizás"," r"," raras"," repente"," s"," salvo"," se"," sé"," segun"," según"," ser"," sera"," será"," si"," sí"," sido"," siempre"," sin"," sobre"," solamente"," solo"," sólo"," son"," soyos"," su"," supuesto"," sus"," suya"," suyas"," suyo"," t"," tal"," tambien"," también"," tampoco"," tarde"," te"," temprano"," ti"," tiene"," todavia"," todavía"," todo"," todos"," tras"," tu"," tú"," tus"," tuya"," tuyas"," tuyo"," tuyos"," u"," un"," una"," unas"," uno"," unos"," usted"," ustedes"," v"," veces"," vez"," vosotras"," vosotros"," vuestra"," vuestras"," vuestro"," vuestros"," w"," x"," y"," ya"," yo","z"]

chars = ["\n","\"","\r","<AUTHOR>","</AUTHOR>",".",",","-","<",">","(",")","?","!"] #"
links = r"\b((https?:\/\/)?([\da-z0-9\.-]+)\.([a-z0-9\.]{2,6})([\/\w\.-]*)*\/?)\b"
function estandarizar(texto)
	texto = lowercase(texto)
	texto = replace(texto,links,"")
	texto = replace(texto,Regex("/\b(rt)\b/"),"")
	texto = replace(texto,"\n","")
	texto = replace(texto,"\"","")
	texto = replace(texto,"\r","")
	texto = replace(texto,"<AUTHOR>","")
	texto = replace(texto,"</AUTHOR>","")
	texto = replace(texto,"'","")
	texto = replace(texto,".","")
	texto = replace(texto,",","")
	texto = replace(texto,"-","")
	texto = replace(texto,"<","")
	texto = replace(texto,">","")
	texto = replace(texto,"(","")
	texto = replace(texto,")","") #" 
	texto = replace(texto,"?","")  
	texto = replace(texto,"!","")  
	texto = replace(texto,"¿","")  
	texto = replace(texto,"¡","")  
	texto = replace(texto,"#","")
	texto = replace(texto,"@","")  
	#texto = removerStopWords(texto)
	texto = removerNumeros(texto)
	#for word in chars
	#	texto = replace(texto,word," ")
	#end
	
	return texto
end
function removerNumeros(texto)
	texto = replace(texto,r"[0-9]","")
	return texto
end
function removerStopWords(texto)
	#for word in stopwords
		#println(word)
		words = r"\b(de|a|y|en|la|el|que|rt|con|los|una|un|es)\b"
		texto = replace(texto, words,"")
	#end
	return texto
end
