#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Este script solo puede ejecutarse como root."
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Uso de la herramienta:"
    echo "  compilador [archivo.c] [nombre_de_salida] [-opcion  o --opcion]"
    echo
    echo "Argumentos:"
    echo "  archivo.c         Archivo fuente en C que se va a compilar (obligatorio)"
    echo "  nombre_de_salida  Nombre del ejecutable que se generará (obligatorio)"
    echo
    echo "Opciones(obligatorio):"
    echo "  -h, --help        Muestra esta ayuda"
    echo "  -f, --fopenmp     Compila el archivo con OpenMP ideal para cuando se activa #pragma omp(solo cuando se usa OpenMP)"
    echo "  -l  --gsl	      Compila el archivo con GSL (Solo cuando se usa GSL)"
    echo "  -fl               Si el programa usa GSL y OpenMP al mismo tiempo"
    echo "  -n  --normal      Compila de forma normal el archivo"
    echo "  -p  --pthread     Es necesario para evitar errores en la compilacion con la libreria de <pthread.h>"
	echo "  -G  --GLU	 	  Compila para GLU"
	exit 0
fi

if [[ -z "$1"  ||  -z "$2"  || -z "$3" ]]; then
    echo -e "\nUso de la herramienta: compilador [archivo.c] [nombre_de_salida] -Opcion \nDezpliegue el menu con 'compilador --help'\n"
  exit 1
fi

archivo="$1"
salida="$2"
opcion="$3"
# ! -f-> el -f es para verificar si existe un archivo y se le agregamos el ! es , sino existe , entonces haz esto  y ya
if [ ! -f "$archivo" ]; then
    echo -e "Error: El archivo $archivo no existe.\n"
 exit 1
fi

# Aqui existe un problema y es el identificar si estamos usando C++ o C, por cuestion de compilacion
# para los archivos C++ se utiliza la libreria estandar de <iostream>, por lo tanto se compila con  'g++' .cpp
# para los archivos C se utiliza la libreria estandar de <stdio.h>, por lo tanto se compila con 'gcc' .c
#Ahora necesitamos detectar que tipo de compilacion es la adecuado para cada codigo que queremos para poder compilarlo correctamente.... :b
#Para poder entrar a un archivo y buscar alguna palabra clave(en linux), se utiliza el comando 'grep'
#Ejem:  grep [palabra_clave] [Archivo]
# La opcion -q ----> grep -q : (quiet) o silencioso No nos imprime la linea exacta donde aparece la palabra clave 

if [[ "$archivo" == *.cpp ]] || grep -q "<iostream>" "$archivo"; then
	COMPILADOR="g++"	#Para cuando es lenguaje C
else
	COMPILADOR="gcc" 	#Sino es lenguaje C++  obviiio >:V
fi

#Ahora que diferenciamos de los archivos C y C++, simplemente concatenamos a la linea de compilacion...
case "$opcion" in
	-f|--fopenmp)
		$COMPILADOR -fopenmp -o "$salida" "$archivo" 2>err.log
	;;
	-l|--gsl)
		$COMPILADOR -o "$salida" "$archivo" -lgsl -lgslcblas -lm 2>err.log
	;;
	-fl)
		$COMPILADOR -fopenmp -o "$salida" "$archivo" -lgsl -lgslcblas -lm 2>err.log
	;;
	-n|--normal)
		$COMPILADOR -o "$salida" "$archivo" 2>err.log
	;;
	-p|--pthread)
		$COMPILADOR "$archivo" -o "$salida" -pthread 2>err.log
	;;
	-G|--GLU)
		$COMPILADOR "$archivo" -o "$salida" -lGL -lGLU -lglut -lm 2>err.log
	;;
	*)
esac

#Persiste un problema y es que, Que pasa si nosotros le pasamos un parametros que no corresponde con el archivo?
#Esto puede llevar a que el programa falle entonces vamos a capturar ese error en un archivo y con el mismo metodo que hicimos para
#detectar que tipo de opcion en base a palabras clave dentro de esa captura de error...
# $? =0 --> El comando se ejecuto correctamente
# $? != 0 ---> EL comando  fallo o devolvio un error
# -ne ---> Distinto de 0
#Si se ejecuta correctamente y devuleve un valor diferente de 0 y es cuando hay un error
#Entonces tomamos el arcviho de captura de errores para poder determinar cual fue el error..
#si en el archivo esta el error de incompatibilidad a la hora de tratar de compilar con OpenMP y es un archivo con GSL
# Aparece el error de 'gsl_......' entonces le mandamos un mensaje al usuario que use el parametro '-l' que es para GSL
#Sino aparece ese error entonces se utiliza '-f' que es con OpenMP
#EL archivo  donde se guarda el error lo borramos al finalizar la ejecucion del programa
if [ $? -ne 0 ]; then
	echo -e "Error: Opcion no correspodiente\n"
	if grep -q "undefined reference" err.log; then

		if grep -q "gsl_" err.log; then
			echo -e "\nEl programa utiliza GSL...\n"
			echo -e "Usa la opcion correcta: -l solo GSL o -fl GSL + OpenMP\n"

		elif grep -q "GL/glut.h" err.log; then
			echo -e "\nEL programa utiliza GL...\n"
			echo -e "Usa la opcion correcta: -G o --GLU\n" 

		else 
			echo -e "Usa la opcion correcta: -f solo OpenMP o -fl GSL + OpenMP\n"
			
		fi
	fi

	echo -e "Detalles del error:\n"
	cat err.log
	rm err.log
	exit 1
else
	echo -e "Compilacion finalizada...\n"
	rm err.log
fi

echo -e "\n\n"
./"$salida"
