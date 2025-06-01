import yt_dlp
import os
import sys
import subprocess
import tempfile
import shutil
import uuid
from pathlib import Path

# Auto-install dependencies if not present
try:
    from pyffmpeg import FFmpeg
except ImportError:
    print("Instalando pyffmpeg (necessário para processamento de áudio/vídeo)...")
    subprocess.call([sys.executable, "-m", "pip", "install", "pyffmpeg"])
    from pyffmpeg import FFmpeg

def get_ffmpeg_path():
    """Obtém o caminho para o binário ffmpeg através do pyffmpeg"""
    try:
        ff = FFmpeg()
        
        # Tentamos vários métodos para obter o caminho
        if hasattr(ff, 'ffmpeg_bin'):
            path = ff.ffmpeg_bin
        elif hasattr(ff, '_FFmpeg__ff_bin'):
            path = ff._FFmpeg__ff_bin
        else:
            # Procura no diretório padrão onde pyffmpeg instala o ffmpeg
            home = str(Path.home())
            default_path = os.path.join(home, '.pyffmpeg', 'bin', 'ffmpeg')
            if os.path.exists(default_path):
                path = default_path
            else:
                raise Exception("Não foi possível encontrar o caminho do ffmpeg")
        
        print(f"ℹ️ Usando ffmpeg embutido do pyffmpeg: {path}")
        return path
    except Exception as e:
        print(f"⚠️ Erro ao localizar ffmpeg: {e}")
        return None

def get_url() -> str:
    return input("\n🔗 Digite a URL do YouTube: ").strip()

def get_output_path() -> str:
    # Obtém o caminho padrão de Downloads
    default_downloads_path = str(Path.home() / "Downloads")

    while True:
        print(f"\nDigite o caminho da pasta de saída (ou arraste a pasta para aqui)")
        print(f"(Pressione Enter para usar o padrão: {default_downloads_path})")
        print("Digite '0' para cancelar e voltar ao menu")
        path_input = input("\n📁 Caminho: ").strip()
        
        if path_input == '0':
            return None
        
        # Se o usuário pressionar Enter, use o caminho padrão
        if not path_input:
            path = default_downloads_path
            print(f"INFO: Usando pasta Downloads padrão: {path}")
        else:
            path = path_input
            
        path = path.strip('"').strip("'")
        path = path.replace('\\\\ ', ' ') 
        path = path.replace('\\ ', ' ')
        
        # Verifica se o diretório existe
        if os.path.isdir(path):
            return path
        elif path == default_downloads_path and not os.path.exists(path):
            try:
                os.makedirs(path)
                print(f"INFO: Pasta Downloads padrão criada: {path}")
                return path
            except OSError as e:
                print(f"❌ ERRO: Não foi possível criar a pasta Downloads padrão: {path}\n{e}")
                continue 
        print("❌ Caminho de pasta inválido. Tente novamente ou verifique as permissões.")

def download_audio(url: str, output_path: str, ffmpeg_path: str) -> None:
    ydl_opts = {
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '320',
        }],
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
        'verbose': True,
        'noprogress': False,
        'ffmpeg_location': ffmpeg_path,  # Usa o caminho do ffmpeg do pyffmpeg
        'progress_hooks': [lambda d: print_progress(d)]
    }
    
    print("\n⏳ Baixando áudio...")
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        print("✅ Download de áudio concluído!")
    except Exception as e:
        print(f"\n❌ Erro durante o download de áudio: {str(e)}")

def download_video(url: str, output_path: str, ffmpeg_path: str) -> None:
    ydl_opts = {
        'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
        'verbose': True,
        'noprogress': False,
        'ffmpeg_location': ffmpeg_path,  # Usa o caminho do ffmpeg do pyffmpeg
        'progress_hooks': [lambda d: print_progress(d)]
    }
    
    print("\n⏳ Baixando vídeo...")
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        print("✅ Download de vídeo concluído!")
    except Exception as e:
        print(f"\n❌ Erro durante o download de vídeo: {str(e)}")

def download_video_protools(url: str, output_path: str, ffmpeg_path: str) -> None:
    ydl_opts = {
        'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
        'verbose': True,
        'noprogress': False,
        'ffmpeg_location': ffmpeg_path,  # Usa o caminho do ffmpeg do pyffmpeg
        'progress_hooks': [lambda d: print_progress(d)],
        'postprocessors': [{
            'key': 'FFmpegVideoConvertor',
            'preferedformat': 'mp4',
        }],
        'postprocessor_args': [
            '-vcodec', 'h264',
            '-acodec', 'aac',
            '-strict', 'experimental',
            '-b:a', '320k',
            '-ar', '48000',
            '-movflags', '+faststart'
        ],
    }
    
    print("\n⏳ Baixando e otimizando vídeo para Pro Tools...")
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
        print("✅ Download e otimização de vídeo concluídos!")
    except Exception as e:
        print(f"\n❌ Erro durante o download de vídeo para Pro Tools: {str(e)}")

def print_progress(d):
    if d['status'] == 'downloading':
        p = d.get('_percent_str', '?%')
        speed = d.get('_speed_str', '? KiB/s')
        eta = d.get('_eta_str', '? s')
        print(f'\rBaixando: {p} a {speed}, ETA: {eta}', end='')
    if d['status'] == 'finished':
        print('\rDownload finalizado. Processando...')

def main_menu():
    # Obtém o caminho do ffmpeg embutido no pyffmpeg
    ffmpeg_path = get_ffmpeg_path()
    if not ffmpeg_path:
        print("❌ ERRO CRÍTICO: Não foi possível encontrar o ffmpeg através do pyffmpeg.")
        print("Por favor, verifique se o pyffmpeg está instalado corretamente.")
        print("Tentando instalar pyffmpeg novamente...")
        subprocess.call([sys.executable, "-m", "pip", "install", "--force-reinstall", "pyffmpeg"])
        ffmpeg_path = get_ffmpeg_path()
        if not ffmpeg_path:
            print("❌ Falha ao instalar/configurar o pyffmpeg. O programa pode não funcionar corretamente.")
    
    while True:
        print("\n=== 📺 Aquisição de Conteúdo do YouTube ===")
        print("1. 🎵 Baixar Somente Áudio (MP3)")
        print("2. 🎥 Baixar Vídeo (Melhor Qualidade)")
        print("3. 🎬 Baixar Vídeo (Otimizado para Pro Tools)")
        print("0. ↩️ Voltar ao Menu Principal (Sair do Script)")

        try:
            choice = input("\nDigite sua escolha (0-3): ").strip()

            if choice == "0":
                print("Saindo do YouTube Downloader.")
                break
                
            elif choice in ["1", "2", "3"]:
                url = get_url()
                if not url:
                    print("❌ URL não pode estar vazia.")
                    continue
                
                output_path = get_output_path()
                if output_path is None:
                    continue
                
                # Verifica novamente se temos o caminho do ffmpeg
                if not ffmpeg_path:
                    print("⚠️ Aviso: O caminho do ffmpeg não está disponível. Tentando continuar mesmo assim...")
                
                if choice == "1":
                    download_audio(url, output_path, ffmpeg_path)
                elif choice == "2":
                    download_video(url, output_path, ffmpeg_path)
                else:
                    download_video_protools(url, output_path, ffmpeg_path)
                    
            else:
                print("❌ Por favor, digite uma opção válida (0-3)")
                
        except Exception as e:
            print(f"\n❌ Ocorreu um erro inesperado no menu: {str(e)}")
            
        input("\nPressione Enter para continuar...")

if __name__ == "__main__":
    # Instalando dependências (isso também é feito no início do script)
    try:
        import yt_dlp
    except ImportError:
        print("Instalando yt-dlp...")
        subprocess.call([sys.executable, "-m", "pip", "install", "yt-dlp"])
        import yt_dlp
    
    main_menu() 