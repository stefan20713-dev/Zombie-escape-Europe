extends RefCounted
class_name QADiagnostics

static func enabled() -> bool:
	return OS.is_debug_build() or OS.has_feature("qa_release")
