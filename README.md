# PDF imzalama

Bu proje, AKİS akıllı kartındaki sertifikayı PKCS#11 üzerinden kullanarak PDF
dosyalarını PAdES imzası ve zaman damgasıyla imzalar. İmzalanan dosya, önce
geçici bir dosyada doğrulanır; doğrulama başarılı olursa hedef konuma taşınır.
İmzalama için [pyHanko][pyhanko] CLI aracı kullanılır.

## Gereksinimler

### Ubuntu

PC/SC altyapısını kurun:

```bash
sudo apt update
sudo apt install pcscd libccid pcsc-tools
```

AKİS sürücülerini [Kamu SM Sürücü Yükleme Servisi][kamusm-drivers]
sayfasından indirin. Arşivden çıkan iki `.deb` paketini kurun:

```bash
sudo dpkg -i ./*.deb
sudo apt-get install -f
```

Ardından `uv` ile pyHanko CLI aracını, PKCS#11 desteğiyle kurun:

```bash
uv tool install --with 'pyHanko[pkcs11]' pyhanko-cli
```

`uv` kurulu değilse [resmi kurulum yönergelerini][uv-install] izleyin.

### macOS

macOS desteği şimdilik **TODO** durumundadır. AKİS PKCS#11 sürücü yolu ve
pyHanko yapılandırması henüz tanımlanmadığı için `imzala` macOS'ta çalışmaz.

### Windows

AKİS sürücülerini [Kamu SM Sürücü Yükleme Servisi][kamusm-drivers]
sayfasından indirin ve kurun. Python ile `uv` kurulumu için Scoop kullanabilirsiniz:

```powershell
scoop install python uv
uv tool install --with 'pyHanko[pkcs11]' pyhanko-cli
```

`pyhanko` komutu PATH üzerinde görünmüyorsa yeni bir terminal açın veya:

```powershell
uv tool update-shell
```

komutunu çalıştırın.

## Kullanım

Ubuntu'da:

```bash
./imzala INPUT.pdf
./imzala INPUT.pdf OUTPUT.pdf
```

Windows'ta:

```powershell
.\imzala.cmd INPUT.pdf
.\imzala.cmd INPUT.pdf OUTPUT.pdf
```

macOS'ta kullanım şimdilik desteklenmiyor.

Çıktı dosyası belirtilmezse giriş dosyasının yanına
`INPUT-signed.pdf` adıyla oluşturulur. Var olan bir çıktı dosyası üzerine
yazılmaz.

## Yapılandırma

`imzala`, Ubuntu/Linux dalında `/usr/lib/libakisp11.so` sürücü modülünü;
`imzala.cmd` ise Windows'ta `C:\Windows\System32\akisp11.dll` dosyasını
kullanır. macOS sürücü yolu için TODO bırakılmıştır.

`pyhanko.yml`, imza ayarlarının yanı sıra imza doğrulamasında kullanılan şu
sertifikaları da belirtir:

- `kamusm-root-v6.crt`
- `kamusm-nes-v6.crt`

Bu dosyalar `imzala` ve `pyhanko.yml` ile aynı dizinde kalmalıdır.

[kamusm-drivers]: https://kamusm.bilgem.tubitak.gov.tr/islemler/surucu_yukleme_servisi/
[pyhanko]: https://github.com/MatthiasValvekens/pyHanko
[uv-install]: https://docs.astral.sh/uv/getting-started/installation/
