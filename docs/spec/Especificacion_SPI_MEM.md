
# Especificación Técnica — SPI_MEM (Vista de Ingeniero de Software)

**Fecha:** 16-Oct-2025  
**Repositorio de fuentes:** `spi_mem_top.sv`, `spi_mem_intf.sv`, `spi_mem.sv`

> Nota: El código fuente proporcionado contiene secciones omitidas con `...`. Esta especificación se basa en el comportamiento observable en el código disponible y en inferencias razonables de un diseño típico de memoria SPI simple. Cualquier punto marcado como **[asumido]** debe confirmarse con el RTL completo o con el autor original.

---

## 1. Resumen ejecutivo

El diseño implementa una memoria de 32 posiciones × 8 bits accesible mediante una interfaz tipo SPI minimalista. Consta de tres módulos:

- `spi_mem_top`: Top de sistema y **API lógica** para software/firmware: expone operaciones de lectura y escritura byte a una dirección de 8 bits, más indicadores `done` y `err`.
- `spi_mem_intf`: Máquina de estados **maestra SPI** que traduce solicitudes de alto nivel (`wr`, `addr`, `din`) a señales de bus serie (`cs`, `mosi`) y recolecta `dout`. Gestiona errores de dirección.
- `spi_mem`: **Esclavo SPI** con RAM interna `mem[31:0]` de 8 bits. Recibe y/o transmite datos serie, y genera `ready`/`op_done` para sincronización.

---

## 2. Mapa de memoria

- **Tamaño:** 32 bytes (direcciones `0x00` … `0x1F`).
- **Reset:** todo el arreglo inicializado en `0x00` (`'{default:0}` en `spi_mem.sv`).  
- **Fuera de rango:** direcciones `≥ 32` deben provocar `err=1` (observado en `spi_mem_intf.sv`) y se evita activar el ciclo SPI (CS permanece alto).

---

## 3. Interfaz de alto nivel (módulo `spi_mem_top`)

### 3.1 Puertos
- **Entradas**
  - `clk` : reloj de sistema.
  - `rst` : reset síncrono activo alto.
  - `wr`  : `1`=escritura, `0`=lectura.
  - `addr[7:0]` : dirección lógica (8 bits).
  - `din[7:0]`  : dato a escribir (válido si `wr=1`).

- **Salidas**
  - `dout[7:0]` : dato leído (válido cuando `done=1` y `wr=0`).
  - `done`      : pulso/flag de operación completada.
  - `err`       : error (p. ej., dirección fuera de rango).

### 3.2 Protocolo de uso (sincrónico)
1. Software coloca `wr`, `addr`, `din` (si aplica) y mantiene estables por al menos **1 ciclo**.
2. El top inicia la transacción SPI vía `spi_mem_intf`.
3. Al completar, `done` se pone a `1` por **[asumido]** un ciclo; si `wr=0`, `dout` contiene el byte leído.
4. Si la dirección es inválida (`addr>31`), `err=1` y **no** se inicia SPI.

**Timing mínimo recomendado (desde SW):**
- Esperar `done==1` antes de iniciar otra operación. Evitar back-to-back sin consultar `done`.

---

## 4. Interfaz de bus SPI (entre `spi_mem_intf` y `spi_mem`)

### 4.1 Señales
- `cs` (salida de `intf`, entrada de `mem`): chip select activo **bajo**.
- `mosi` (salida de `intf`, entrada de `mem` como `miso` en el archivo): datos maestro→esclavo.
- `miso` (salida de `mem`, entrada de `intf` como `miso`/`misoreg`): datos esclavo→maestro. **[asumido por convención]**
- `ready` (salida de `mem`): el esclavo está listo para una nueva transacción.
- `op_done` (salida de `mem`): el esclavo afirma fin de operación.

> **Nota de nomenclatura:** En `spi_mem.sv` el puerto se llama `miso` como **entrada**; esto sugiere que el archivo usa la perspectiva del esclavo (recibe del maestro). `spi_mem_intf.sv` produce `mosi` y muestrea `miso`. La dirección de nombres es consistente con un bus SPI convencional.

### 4.2 Frame y orden de bits
- `spi_mem.sv` captura un vector `datain[15:0]` usando un contador `count` 0..15 y al llegar a 16 bits hace:  
  `mem[datain[7:0]] <= datain[15:8];`  
  **Interpretación:** Se reciben **16 bits** en un único frame:
  - Bits [15:8] = **dato** (byte)
  - Bits [7:0]  = **dirección**
- **Orden de bits** (MSB/LSB first) **[asumido]**: por construcción tipo shift se **asume** MSB-first. Confirmar en RTL completo.

### 4.3 Operaciones soportadas
- **Escritura (wr=1 en `top`):** `intf` baja `cs` y envía 16 bits por `mosi`: `dato (8b)` seguido de `dirección (8b)`. El esclavo almacena y eleva `op_done`.
- **Lectura (wr=0 en `top`):** **[asumido]** `intf` baja `cs`, envía `dirección (8b)` y lee un byte devuelto por el esclavo por `miso`. El byte se propaga como `dout` en el `top`.

> **Importante:** En el RTL visible no aparece un **opcode** de lectura/escritura; la dirección de escritura se infiere por el almacenamiento. Para lectura, el esclavo likely usa un estado `send_*` que recorre el dato presente en `mem[addr]`. Debe verificarse con el código completo.

---

## 5. Máquinas de estados

### 5.1 `spi_mem_intf` (maestro)
Estados observables (nombres aproximados por fragmentos visibles): `idle`, `check_addr`, `send_data`, `read_data1/2`, `error`, `complete` **[nombres y transiciones parcialmente asumidos]**.

- `idle`: espera nueva orden; limpia `count`, `mosi`, `cs=1`.
- `check_addr`: si `addr <= 31` continúa; si no, `state=error` y `cs` **permanece alto** (memoria no entra en ciclo).
- `send_data`: serializa en `mosi` los 16 bits (para escritura) o 8 bits de dirección (para lectura). Avanza con `count` hasta 16/8.
- `read_data*`: muestrea bits que llegan por `miso` y arma `dout_reg`.
- `error`: fuerza `err=1`, `cs=1`, termina con `done=1` sin tocar el bus.
- `complete`: levanta `done`, pone `cs=1` y regresa a `idle`.

### 5.2 `spi_mem` (esclavo)
Estados observables: `idle`, `store` (captura), `send` (emisión), `finish` **[asumido]**.

- `idle`: `ready=1`, `op_done=0`, espera `cs==0`.
- `store`: mientras `count<=15` captura bits de `miso` (maestro→esclavo). En `count==16`: `mem[addr]<=data; op_done=1; count=0; state=idle`.
- `send`: cuando es lectura, **[asumido]** desplaza a `mosi` el byte de `mem[addr]`.
- `finish`: asegura `op_done=1` por un ciclo, luego vuelve a `idle`.

---

## 6. Reset y condiciones de error

- **Reset (`rst` alto):**
  - `spi_mem_top`: limpia `done`, `err`, señales intermedias **[asumido]**.
  - `spi_mem_intf`: vuelve a `idle`, `cs=1`, `mosi=0`, `count=0`, `dout_reg=0`.
  - `spi_mem`: RAM inicializada a cero; `ready=0 → 1` tras salir de reset (según lógica observada); `op_done=0`, `count=0`.

- **Errores:**
  - `addr > 31` ⇒ `err=1`, no se activa el bus (`cs` se mantiene en alto), `done=1`.
  - **[asumido]** No hay paridad/CRC; el único error detectable es fuera de rango.

---

## 7. Requisitos temporales (software ↔ hardware)

- **Setup de solicitud:** Estabilizar `wr/addr/din` ≥ 1 ciclo antes de evaluar `done`.
- **Latencia típica:** Escritura: 16 ticks de reloj SPI interno + sobrecosto de estados. Lectura: 8 (dirección) + 8 (dato) ticks. (**[asumido]**)
- **Back-to-back:** Esperar `done==1` y luego a que `done` retorne a `0` antes de iniciar nueva operación.
- **CS:** activo bajo durante la transferencia; se libera alto al finalizar.

---

## 8. Secuencias de uso (pseudocódigo)

### 8.1 Escribir un byte
```c
bool spi_mem_write(uint8_t addr, uint8_t data) { 
  if (addr >= 32) return false;         // valida en SW también
  wr   = 1; 
  din  = data; 
  a    = addr;
  start_cycle();                         // coloca señales y da 1 ciclo
  wait_until(done == 1);
  return err == 0;
}
```

### 8.2 Leer un byte
```c
bool spi_mem_read(uint8_t addr, uint8_t* out) {
  if (addr >= 32) return false;
  wr   = 0; 
  a    = addr;
  start_cycle();
  wait_until(done == 1);
  if (err) return false;
  *out = dout;
  return true;
}
```

---

## 9. Consideraciones de verificación

- **Cobertura funcional mínima:**
  - Escrituras/lecturas a `0x00`, `0x1F` y direcciones intermedias.
  - Dirección fuera de rango (`0x20`/`0xFF`) ⇒ `err=1`, `cs` nunca baja.
  - Back-to-back write/read sin reset intermedio.
  - Reset durante `send_data` y durante `store`.
  - Aleatorizar `din`, `addr`, y pausas entre operaciones.
- **Scoreboard:** RAM espejo de 32B; comparar tras `done`.
- **Monitores:** transición `cs` (baja/sube), conteo de 16/8 flancos, estabilidad de `mosi` alrededor del flanco activo (mode **[asumido]** CPOL/CPHA=0).
- **Assertions sugeridas:**
  - `addr>31 |-> cs==1 && done` dentro de `N` ciclos.
  - `cs==0` ⇒ exactamente 16 shifts en escritura.
  - Tras `op_done`, retorno a `idle` en ≤ `M` ciclos.

---

## 10. Interfaz y parámetros configurables

- **Parámetros:** no se observan `parameter` públicos en los encabezados; tamaño fijo 32B.  
  **Extensibilidad:** convertir `DEPTH` y `AW` en parámetros y derivar el chequeo `addr < DEPTH` en `intf` y en `mem`.

---

## 11. Riesgos y puntos a confirmar (**acciones abiertas**)

1. **Orden de bits y modo SPI (CPOL/CPHA).** Confirmar para alinear el muestreo en `intf` y `mem`.
2. **Secuencia de lectura exacta.** El esclavo debe tener estados de envío; revisar el RTL completo para documentar cronograma exacto de 8/16 ticks.
3. **Duración de `done`/`op_done`.** ¿pulso de 1 ciclo o nivel hasta que se reconozca?
4. **Sincronización `ready`.** ¿El maestro espera `ready==1` antes de bajar `cs`? En `spi_mem_top.sv` aparecen señales `readyreg/misoreg`; validar handshake.

---

## 12. Anexos

### 12.1 Encabezados observados (resumen)

- `spi_mem_top.sv`:
  ```verilog
  module spi_mem_top(
    input  wr, clk, rst,
    input  [7:0] addr, din,
    output [7:0] dout,
    output done, err
  );
  ```

- `spi_mem_intf.sv`:
  ```verilog
  module spi_mem_intf(
    input wr, clk, rst, ready, op_done,
    input [7:0] addr, din,
    output [7:0] dout,
    output reg cs, mosi,
    // ... recibe miso del esclavo (no visible en el recorte), produce done/err/dout_reg
  );
  ```

- `spi_mem.sv`:
  ```verilog
  module spi_mem(
    input clk, rst, cs, miso,
    output reg ready, mosi, op_done
  );
  // reg [7:0] mem [31:0] = '{default:0};
  // integer count; reg [15:0] datain;
  // store: al completar 16 bits => mem[datain[7:0]] <= datain[15:8];
  ```

### 12.2 Diagrama de secuencia (alto nivel)

```
SW      spi_mem_top     spi_mem_intf         spi_mem (esclavo)
 | wr/addr/din |              |                         |
 |------------>|              |                         |
 |             |  valida dir  |                         |
 |             |-------------->|                         |
 |             |  cs=0, shift dato/dir (16b)            |
 |             |--------------------------------------->|
 |             |                          almacena/lee  |
 |             |<---------------------------------------|  miso (lectura)
 |             | cs=1, done=1                            |
 |<------------|                                         |
```

---

## 13. Licencia y autoría

- Comentarios de cabecera indican propósito didáctico (“Ejercicio: Verificación de SPI-MEM — UVM”).
- No se especifica licencia; asumir uso interno educativo salvo aclaración.

---

**Fin del documento.**
