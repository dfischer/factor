DLLEXPORT CELL alien_temp;

INLINE F_ALIEN* untag_alien_fast(CELL tagged)
{
	return (F_ALIEN*)UNTAG(tagged);
}

CELL allot_alien(CELL delegate, CELL displacement);

void primitive_expired(void);
void primitive_displaced_alien(void);
void primitive_alien_address(void);

void* alien_offset(CELL object);

void fixup_alien(F_ALIEN* d);

DLLEXPORT void *unbox_alien(void);
DLLEXPORT void box_alien(void *ptr);

void primitive_alien_signed_cell(void);
void primitive_set_alien_signed_cell(void);
void primitive_alien_unsigned_cell(void);
void primitive_set_alien_unsigned_cell(void);
void primitive_alien_signed_8(void);
void primitive_set_alien_signed_8(void);
void primitive_alien_unsigned_8(void);
void primitive_set_alien_unsigned_8(void);
void primitive_alien_signed_4(void);
void primitive_set_alien_signed_4(void);
void primitive_alien_unsigned_4(void);
void primitive_set_alien_unsigned_4(void);
void primitive_alien_signed_2(void);
void primitive_set_alien_signed_2(void);
void primitive_alien_unsigned_2(void);
void primitive_set_alien_unsigned_2(void);
void primitive_alien_signed_1(void);
void primitive_set_alien_signed_1(void);
void primitive_alien_unsigned_1(void);
void primitive_set_alien_unsigned_1(void);
void primitive_alien_float(void);
void primitive_set_alien_float(void);
void primitive_alien_double(void);
void primitive_set_alien_double(void);

DLLEXPORT void unbox_value_struct(void *dest, CELL size);
DLLEXPORT void box_value_struct(void *src, CELL size);
DLLEXPORT void box_value_pair(CELL x, CELL y);

INLINE F_DLL *untag_dll(CELL tagged)
{
	type_check(DLL_TYPE,tagged);
	return (F_DLL*)UNTAG(tagged);
}

void primitive_dlopen(void);
void primitive_dlsym(void);
void primitive_dlclose(void);