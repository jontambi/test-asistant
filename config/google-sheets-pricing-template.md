# Google Sheets Pricing Template

## Setup Instructions

### 1. Create a New Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Create a new spreadsheet
3. Name it: "Kids Growing - Tarifas y Servicios"

### 2. Sheet Structure

Create a sheet named **"Tarifas"** with the following columns:

| Column | Header | Description | Example |
|--------|--------|-------------|---------|
| A | Categoría | Service category | Consulta |
| B | Nombre del Servicio | Service name | Consulta Pediátrica General |
| C | Descripción | Service description | Evaluación completa del estado de salud del niño |
| D | Precio | Price | $500 MXN |
| E | Notas | Additional notes | Incluye receta médica |

### 3. Sample Data

Copy and paste this data into your Google Sheet:

```
Categoría	Nombre del Servicio	Descripción	Precio	Notas
Consulta	Consulta Pediátrica General	Evaluación completa del estado de salud del niño	$500 MXN	Incluye receta médica
Consulta	Control de Niño Sano	Seguimiento del desarrollo y crecimiento	$450 MXN	Recomendado cada 3 meses
Consulta	Consulta de Urgencia	Atención inmediata para casos urgentes	$800 MXN	Disponible en horario de oficina
Vacuna	Vacuna Triple Viral (SRP)	Protección contra sarampión, rubéola y paperas	$350 MXN	Incluye aplicación y certificado
Vacuna	Vacuna Influenza	Protección contra la gripe estacional	$250 MXN	Recomendada anualmente
Vacuna	Vacuna Hexavalente	6 enfermedades en una sola aplicación	$600 MXN	Incluye seguimiento
Procedimiento	Curación de Heridas	Limpieza y vendaje de heridas menores	$300 MXN	No incluye suturas
Procedimiento	Nebulización	Tratamiento respiratorio	$200 MXN	Por sesión
Procedimiento	Extracción de Cuerpo Extraño	Remoción de objetos en nariz u oído	$400 MXN	Evaluación médica incluida
Especialidad	Consulta Cardiología Pediátrica	Evaluación cardiovascular especializada	$900 MXN	Requiere cita previa
Especialidad	Consulta Neurología Pediátrica	Evaluación neurológica especializada	$900 MXN	Requiere cita previa
Examen	Examen General de Orina	Análisis de laboratorio	$150 MXN	Resultados en 24h
Examen	Biometría Hemática Completa	Análisis de sangre completo	$200 MXN	Resultados en 24h
Examen	Prueba de Alergias (Panel Básico)	Detección de alergias comunes	$800 MXN	Incluye interpretación médica
Certificado	Certificado Médico Escolar	Para inscripción o actividades escolares	$200 MXN	Entrega inmediata
Certificado	Certificado para Deportes	Evaluación para actividades deportivas	$250 MXN	Incluye examen físico
Paquete	Paquete Control Anual	3 consultas + vacunas del año	$1,200 MXN	Ahorro de $150 MXN
Paquete	Paquete Recién Nacido	5 consultas primer año + vacunas	$2,500 MXN	Ahorro de $500 MXN
```

### 4. Google Sheets API Setup

#### 4.1 Enable Google Sheets API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Sheets API
4. Enable the Google Calendar API (for appointments)

#### 4.2 Create Service Account

1. Go to "Credentials" in Google Cloud Console
2. Click "Create Credentials" → "Service Account"
3. Fill in the service account details
4. Grant the service account "Editor" role
5. Click "Done"

#### 4.3 Create Service Account Key

1. Click on the newly created service account
2. Go to "Keys" tab
3. Click "Add Key" → "Create new key"
4. Select "JSON" format
5. Download the JSON file (keep it secure!)

#### 4.4 Share Your Google Sheet

1. Open your pricing Google Sheet
2. Click "Share" button
3. Add the service account email (found in the JSON file)
4. Give "Editor" permission
5. Click "Send"

#### 4.5 Get Your Sheet ID

The Sheet ID is in the URL of your Google Sheet:
```
https://docs.google.com/spreadsheets/d/[SHEET_ID]/edit
```

Copy this ID and add it to your `.env` file as `GOOGLE_SHEET_PRICING_ID`

### 5. N8N Credentials Setup

In N8N, create a Google Sheets credential:

1. Go to Credentials in N8N
2. Click "Add Credential"
3. Select "Google Sheets API"
4. Choose "Service Account" authentication
5. Upload your JSON key file or paste the contents
6. Save with name: "Google Sheets Account"

### 6. Testing

Test your setup by making a request to the pricing workflow:

```bash
curl -X POST https://your-n8n-instance.com/webhook/lucia-pricing \
  -H "Content-Type: application/json" \
  -d '{
    "serviceName": "consulta",
    "sessionId": "test-session"
  }'
```

### 7. Maintenance Tips

- **Regular Updates**: Keep pricing updated monthly
- **Version Control**: Consider keeping a changelog in another sheet
- **Backup**: Download a copy regularly
- **Access Control**: Only share with authorized personnel
- **Audit Trail**: Use Google Sheets version history to track changes

### 8. Advanced: Categories and Filtering

You can add more sheets for different types of data:

- **"Promociones"** - Special offers and discounts
- **"Paquetes"** - Package deals
- **"Seguros"** - Insurance-accepted services
- **"Temporada"** - Seasonal services (flu season, back-to-school)

### 9. Formatting Tips

- Use **data validation** for the "Categoría" column to ensure consistency
- Apply **conditional formatting** to highlight special prices
- Use **currency formatting** for the "Precio" column
- Add **comments** to cells for internal notes (won't be shown to users)
- Consider adding a **"Vigencia"** (validity date) column for time-limited pricing

### 10. Security Best Practices

- **Never** share the service account JSON key
- **Limit** edit access to the sheet
- **Review** the activity log regularly
- **Use** version history to track unauthorized changes
- **Create** a separate sheet for testing vs. production
