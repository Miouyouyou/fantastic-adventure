extends Node

const glb_header_magic:int   = 0x46546C67
const glb_header_version:int = 2

const mime_types:Dictionary = {
	"png": "image/png",
	"jpg": "image/jpg",
	"jpeg": "image/jpg",
	"webp": "image/webp",
	"dds": "image/vnd-ms.dds",
	"glsl": "text/plain",
	"vert": "text/plain",
	"vs": "text/plain",
	"frag": "text/plain",
	"fs": "text/plain",
	"txt": "text/plain"
}

func array_store_uint32(buffer:PoolByteArray, uint32_value:int):
	buffer.append((uint32_value >> 24) & 0xff)
	buffer.append((uint32_value >> 16) & 0xff)
	buffer.append((uint32_value >> 8) & 0xff)
	buffer.append((uint32_value >> 0) & 0xff)

func glb_file_write_header(out_buffer:PoolByteArray, total_size:int):
	array_store_uint32(out_buffer, glb_header_magic)
	array_store_uint32(out_buffer, glb_header_version)
	array_store_uint32(out_buffer, total_size)
	return

func convert_gltf_zip_to_glb(zipdata:PoolByteArray):
	var total_size = 0
	
	return
