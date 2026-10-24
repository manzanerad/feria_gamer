class_name JsonLoader
extends RefCounted
## Funciones de lectura de archivos JSON compartidas por todo el juego.
## Nunca lanzan errores que detengan el juego: si el archivo falta o está mal escrito,
## lo reportan en la consola y devuelven un diccionario vacío para que quien llama use sus valores por defecto.


static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("No existe %s; se usarán valores por defecto." % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("%s tiene un error en la línea %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if json.data is Dictionary:
		return json.data
	push_error("%s no contiene un objeto JSON en la raíz." % path)
	return {}


## Devuelve el número guardado en `key` o `default_value` si no existe o no es un número.
static func read_number(data: Dictionary, key: String, default_value: float) -> float:
	var value: Variant = data.get(key, default_value)
	if value is float or value is int:
		return float(value)
	return default_value
