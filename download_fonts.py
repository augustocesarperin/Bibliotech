import os
import urllib.request

# URLs das fontes Montserrat do Google Fonts CDN
font_urls = {
    "Montserrat-Regular.ttf": "https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCtr6Hw5aXp-p7K4GLs.woff2",
    "Montserrat-Bold.ttf": "https://fonts.gstatic.com/s/montserrat/v26/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCuM73w5aXp-p7K4GLs.woff2",
    "Montserrat-Italic.ttf": "https://fonts.gstatic.com/s/montserrat/v26/JTUFjIg1_i6t8kCHKm459Wx7xQYXK0vOoz6jq6R9WXZ0poK5.woff2"
}

# Cria o diretório para as fontes
fonts_dir = "assets/fonts/Montserrat"
os.makedirs(fonts_dir, exist_ok=True)

# Baixa cada fonte
for font_name, url in font_urls.items():
    font_path = os.path.join(fonts_dir, font_name)
    print(f"Baixando {font_name}...")
    urllib.request.urlretrieve(url, font_path)
    print(f"Fonte salva em {font_path}")

print("Todas as fontes foram baixadas com sucesso!") 