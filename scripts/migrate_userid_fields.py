#!/usr/bin/env python3
"""
Script para migrar datos existentes agregando campo userId
IMPORTANTE: Este script asignará el primer usuario admin como propietario de todos los datos huérfanos
"""

import sys
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin importado correctamente")
except ImportError as e:
    print(f"❌ Error al importar firebase-admin: {e}")
    print("📦 Instalando firebase-admin...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "firebase-admin==7.1.0"])
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin instalado e importado")

def main():
    print("🔄 Migrando datos existentes - Agregando campo userId...")
    print()
    
    # Inicializar Firebase Admin SDK
    try:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK inicializado")
    except Exception as e:
        print(f"❌ Error al inicializar Firebase: {e}")
        print()
        print("💡 Para migración manual:")
        print()
        print("   1. Ve a Firebase Console → Firestore Database")
        print("   2. Para cada documento sin 'userId':")
        print("      • Click en el documento")
        print("      • Click 'Add field'")
        print("      • Field name: userId")
        print("      • Field type: string")
        print("      • Value: [UID del usuario propietario]")
        print("      • Click 'Save'")
        print()
        return
    
    db = firestore.client()
    
    # Buscar primer usuario admin
    print("🔍 Buscando usuario administrador...")
    admin_user = None
    try:
        users = db.collection('users').where('rol', '==', 'admin').limit(1).stream()
        for user in users:
            admin_user = user.to_dict()
            print(f"✅ Usuario admin encontrado: {admin_user['nombre']} (UID: {admin_user['uid']})")
            break
    except Exception as e:
        print(f"❌ Error buscando admin: {e}")
    
    if not admin_user:
        print("⚠️  No se encontró usuario admin. Los datos huérfanos no podrán ser migrados.")
        print("💡 Crea primero un usuario admin antes de ejecutar la migración.")
        return
    
    default_user_id = admin_user['uid']
    print(f"📌 Los datos sin propietario se asignarán a: {admin_user['nombre']}")
    print()
    
    # Preguntar confirmación
    print("⚠️  ADVERTENCIA: Esta operación modificará documentos en Firestore.")
    print()
    response = input("¿Deseas continuar? (escribe 'SI' para confirmar): ")
    if response.upper() != 'SI':
        print("❌ Migración cancelada.")
        return
    
    print()
    print("🚀 Iniciando migración...")
    print()
    
    # Colecciones que deben tener userId
    collections_to_migrate = [
        'properties',
        'rooms',
        'tickets',
        'property_listings',
        'inventory_acts',
        'virtual_tours',
    ]
    
    total_migrated = 0
    
    for collection_name in collections_to_migrate:
        print(f"📂 Migrando colección: {collection_name}")
        
        try:
            # Obtener documentos sin userId
            docs = db.collection(collection_name).stream()
            
            migrated_count = 0
            skipped_count = 0
            
            for doc in docs:
                data = doc.to_dict()
                
                # Si ya tiene userId, saltar
                if 'userId' in data and data['userId']:
                    skipped_count += 1
                    continue
                
                # Agregar userId
                doc.reference.update({'userId': default_user_id})
                migrated_count += 1
                
                if migrated_count % 10 == 0:
                    print(f"   Progreso: {migrated_count} documentos migrados...")
            
            total_migrated += migrated_count
            
            if migrated_count == 0 and skipped_count == 0:
                print(f"   ⚪ Colección vacía (0 documentos)")
            elif migrated_count == 0:
                print(f"   ✅ {skipped_count} documentos ya tenían userId")
            else:
                print(f"   ✅ {migrated_count} documentos migrados exitosamente")
                if skipped_count > 0:
                    print(f"      {skipped_count} documentos ya tenían userId")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")
        
        print()
    
    # Resumen
    print("=" * 60)
    print("📊 RESUMEN DE MIGRACIÓN")
    print("=" * 60)
    print()
    print(f"✅ Total de documentos migrados: {total_migrated}")
    print(f"👤 Propietario asignado: {admin_user['nombre']}")
    print(f"🔑 UID asignado: {default_user_id}")
    print()
    
    if total_migrated > 0:
        print("✅ MIGRACIÓN COMPLETADA")
        print()
        print("💡 Próximos pasos:")
        print("   1. Verificar datos en Firebase Console")
        print("   2. Desplegar reglas de seguridad")
        print("   3. Probar acceso con diferentes usuarios")
        print()
        print("⚠️  IMPORTANTE:")
        print("   • Todos los datos migrados pertenecen ahora al admin")
        print("   • Puedes reasignar manualmente los datos a sus propietarios reales")
        print("   • O eliminar los datos de prueba y crear nuevos con los usuarios correctos")
    else:
        print("✅ NO SE REQUIRIÓ MIGRACIÓN")
        print()
        print("   Todas las colecciones ya tenían el campo userId.")
    
    print()

if __name__ == "__main__":
    main()
