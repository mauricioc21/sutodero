#!/usr/bin/env python3
"""
Script para verificar qué colecciones de Firestore necesitan migración del campo userId
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
    print("🔍 Verificando campos userId en Firestore...")
    print()
    
    # Inicializar Firebase Admin SDK
    try:
        cred = credentials.Certificate("/opt/flutter/firebase-admin-sdk.json")
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK inicializado")
    except Exception as e:
        print(f"❌ Error al inicializar Firebase: {e}")
        print()
        print("💡 ALTERNATIVA: Verificar manualmente en Firebase Console")
        print()
        print("   1. Ve a: https://console.firebase.google.com/")
        print("   2. Selecciona tu proyecto")
        print("   3. Ve a Firestore Database")
        print("   4. Revisa cada colección y verifica si tienen campo 'userId'")
        print()
        print("   Colecciones a verificar:")
        print("   • properties")
        print("   • rooms")
        print("   • tickets")
        print("   • property_listings")
        print("   • inventory_acts")
        print("   • virtual_tours")
        print()
        return
    
    db = firestore.client()
    
    # Colecciones que deben tener userId
    collections_to_check = [
        'properties',
        'rooms',
        'tickets',
        'property_listings',
        'inventory_acts',
        'virtual_tours',
    ]
    
    results = {}
    
    for collection_name in collections_to_check:
        print(f"📂 Verificando colección: {collection_name}")
        
        try:
            # Obtener todos los documentos
            docs = db.collection(collection_name).limit(100).stream()
            
            total_docs = 0
            docs_with_userid = 0
            docs_without_userid = []
            
            for doc in docs:
                total_docs += 1
                data = doc.to_dict()
                
                if 'userId' in data and data['userId']:
                    docs_with_userid += 1
                else:
                    docs_without_userid.append(doc.id)
            
            results[collection_name] = {
                'total': total_docs,
                'with_userid': docs_with_userid,
                'without_userid': len(docs_without_userid),
                'missing_docs': docs_without_userid[:5]  # Solo mostrar primeros 5
            }
            
            if total_docs == 0:
                print(f"   ⚠️  Colección vacía (0 documentos)")
            elif docs_with_userid == total_docs:
                print(f"   ✅ {total_docs} documentos - TODOS tienen userId")
            else:
                print(f"   ⚠️  {total_docs} documentos - {len(docs_without_userid)} SIN userId")
                if docs_without_userid:
                    print(f"      Ejemplos: {', '.join(docs_without_userid[:3])}")
            
        except Exception as e:
            print(f"   ❌ Error: {e}")
            results[collection_name] = {'error': str(e)}
        
        print()
    
    # Resumen
    print("=" * 60)
    print("📊 RESUMEN DE VERIFICACIÓN")
    print("=" * 60)
    print()
    
    needs_migration = []
    all_ok = []
    
    for collection_name, data in results.items():
        if 'error' in data:
            print(f"❌ {collection_name}: Error al verificar")
        elif data['total'] == 0:
            print(f"⚪ {collection_name}: Colección vacía (sin datos)")
        elif data['without_userid'] > 0:
            print(f"⚠️  {collection_name}: {data['without_userid']}/{data['total']} documentos necesitan migración")
            needs_migration.append(collection_name)
        else:
            print(f"✅ {collection_name}: {data['total']}/{data['total']} documentos OK")
            all_ok.append(collection_name)
    
    print()
    print("=" * 60)
    
    if needs_migration:
        print()
        print("🚨 ACCIÓN REQUERIDA")
        print()
        print(f"Las siguientes colecciones necesitan migración:")
        for col in needs_migration:
            print(f"   • {col}")
        print()
        print("💡 Opciones:")
        print("   1. Ejecutar script de migración automática")
        print("   2. Migrar manualmente en Firebase Console")
        print("   3. Eliminar datos antiguos y empezar de nuevo")
    else:
        print()
        print("✅ TODAS LAS COLECCIONES ESTÁN LISTAS")
        print()
        print("   No se requiere migración. Puedes:")
        print("   1. Desplegar las reglas de seguridad")
        print("   2. Crear usuarios de prueba")
        print("   3. Probar la aplicación")
    
    print()

if __name__ == "__main__":
    main()
