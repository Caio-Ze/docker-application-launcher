import yt_dlp
import os
import sys
import subprocess
import tempfile
import shutil
import uuid
from pathlib import Path

def clear_stdin_buffer():
    """Clear any buffered input to prevent confusion"""
    try:
        sys.stdout.flush() # Flush stdout
        sys.stderr.flush() # Flush stderr
        import termios, fcntl
        fd = sys.stdin.fileno()
        # Flush input buffer
        termios.tcflush(fd, termios.TCIFLUSH)
    except:
        # Fallback for systems without termios
        try:
            while sys.stdin.read(1):
                pass
        except:
            pass

def get_ffmpeg_path():
    """Obtém o caminho para o binário ffmpeg."""
    ffmpeg_exe = shutil.which("ffmpeg")
    if ffmpeg_exe:
        print(f"ℹ️ Usando ffmpeg do sistema em: {ffmpeg_exe}")
        return ffmpeg_exe
    else:
        print("⚠️ ERRO CRÍTICO: ffmpeg não encontrado no PATH do sistema.")
        print("Verifique a instalação do ffmpeg no Dockerfile.")
        return None # Return None if not found, to be handled by calling function

def get_url() -> str:
    clear_stdin_buffer()  # Clear any buffered input
    while True:
        try:
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print("\n🔗 Digite a URL do YouTube:")
            url = input("➤ ").strip()
            print(f"🐛 Debug: URL recebida: '{url}'")  # Debug output
            
            if not url:
                print("❌ URL não pode estar vazia. Tente novamente.")
                continue
                
            # Basic URL validation
            if not url.startswith(('http://', 'https://', 'www.', 'youtube.com', 'youtu.be')):
                print(f"❌ URL inválida: '{url}'. Por favor, digite uma URL válida do YouTube.")
                continue
                
            return url
        except (EOFError, KeyboardInterrupt):
            print("\n⚠️ Operação cancelada pelo usuário.")
            return None
        except Exception as e:
            print(f"❌ Erro ao ler URL: {e}")
            continue

def get_output_path() -> str:
    """Get output path using user's actual Downloads folder"""
    # Priority: User's actual Downloads folder (mounted from host)
    host_user_paths = [
        "/host/Users",  # macOS host mount
        "/host/home",   # Linux host mount  
    ]
    
    # Find the user's Downloads folder
    user_downloads = None
    host_user = os.environ.get('HOST_USER', 'user')
    
    for base_path in host_user_paths:
        if os.path.exists(base_path):
            user_home = os.path.join(base_path, host_user)
            if os.path.exists(user_home):
                downloads_path = os.path.join(user_home, "Downloads")
                if os.path.exists(downloads_path) or True:  # Create if doesn't exist
                    try:
                        os.makedirs(downloads_path, exist_ok=True)
                        if os.access(downloads_path, os.W_OK):
                            user_downloads = downloads_path
                            break
                    except:
                        continue
    
    # Fallback options if host mount not available
    fallback_paths = [
        "/app/output",     # Mounted output directory
        "/app/data",       # Mounted data directory
        "/app/downloads",  # App downloads directory
        "/tmp/downloads"   # Last resort
    ]
    
    if not user_downloads:
        for path in fallback_paths:
            try:
                os.makedirs(path, exist_ok=True)
                if os.access(path, os.W_OK):
                    user_downloads = path
                    break
            except:
                continue
    
    if not user_downloads:
        user_downloads = "/tmp/downloads"
        os.makedirs(user_downloads, exist_ok=True)

    clear_stdin_buffer()  # Clear any buffered input
    while True:
        print(f"\n📁 Escolha a pasta de destino (Pressione Enter para padrão: Downloads do Usuário):")
        print(f"1. 📥 Downloads do usuário (recomendado): {user_downloads}")
        print(f"2. 📤 Pasta Docker Application Launcher Output: /app/output")
        print(f"3. 💾 Pasta personalizada (digite o caminho)")
        print(f"0. ❌ Cancelar")
        
        try:
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            choice = input("\nDigite sua escolha (0-3) [Padrão: 1]: ").strip()
            print(f"🐛 Debug: Escolha de pasta: '{choice}'")

            if not choice: # User pressed Enter
                choice = "1"
            
            if choice == "0":
                return None
            elif choice == "1":
                print(f"✅ Usando Downloads do usuário: {user_downloads}")
                return user_downloads
            elif choice == "2":
                fallback_output = "/app/output"
                try:
                    os.makedirs(fallback_output, exist_ok=True)
                except:
                    pass
                print(f"✅ Usando pasta output: {fallback_output}")
                return fallback_output
            elif choice == "3":
                custom_path = input("Digite o caminho completo: ").strip()
                custom_path = custom_path.strip('"').strip("'")
                custom_path = custom_path.replace('\\\\ ', ' ').replace('\\ ', ' ')
                
                if os.path.isdir(custom_path) and os.access(custom_path, os.W_OK):
                    return custom_path
                else:
                    print(f"❌ Caminho inválido ou sem permissão de escrita: {custom_path}")
                    continue
            else:
                print(f"❌ Opção inválida: '{choice}'. Digite 0, 1, 2 ou 3.")
                continue
                
        except (EOFError, KeyboardInterrupt):
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print("\n⚠️ Operação cancelada pelo usuário.")
            return None
        except Exception as e:
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print(f"❌ Erro: {e}")
            continue

def download_audio(url: str, output_path: str, ffmpeg_path: str) -> None:
    """Downloads and extracts audio to MP3 with detailed ffmpeg logging."""
    output_path_str = str(output_path)
    
    temp_info_opts = {'skip_download': True, 'quiet': True, 'no_warnings': True}
    with yt_dlp.YoutubeDL(temp_info_opts) as ydl_info:
        try:
            info_dict = ydl_info.extract_info(url, download=False)
            title = info_dict.get('title', 'downloaded_audio')
            sanitized_title = "".join([c for c in title if c.isalnum() or c in (' ', '-', '_')]).rstrip()
            if not sanitized_title: # Handle cases where title becomes empty after sanitization
                sanitized_title = f"audio_{uuid.uuid4().hex[:8]}"
        except Exception as e_title:
            print(f"⚠️ Erro ao obter título, usando nome padrão: {e_title}")
            sanitized_title = f"audio_{uuid.uuid4().hex[:8]}"

    # yt-dlp will add .mp3 to this template when preferredcodec is 'mp3'
    output_template = os.path.join(output_path_str, f'{sanitized_title}.%(ext)s')
    # We predict the final path for checking later
    final_mp3_path = os.path.join(output_path_str, f'{sanitized_title}.mp3') 

    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_template,
        'verbose': True,
        'noprogress': False,
        'ffmpeg_location': ffmpeg_path,
        'progress_hooks': [lambda d: print_progress(d)],
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '320', # yt-dlp uses this to set -b:a for libmp3lame
        }],
        'postprocessor_args': {
            'extractaudio': [
                '-v', 'debug',       # Max ffmpeg verbosity
                '-progress', '-',    # Pipe progress to stdout/stderr for capture
                '-nostats',          # Disable ffmpeg's own stats printing (yt-dlp handles it)
            ]
        },
        'nocheckcertificate': True,
        'retries': 5,
        'fragment_retries': 5,
        'writedescription': False, # Do not save video description
        'writeinfojson': False,  # Do not save video metadata
        'writethumbnail': False, # Do not save video thumbnail
    }
    
    print(f"\n⏳ Baixando áudio para: {output_template}")
    print(f"💿 Tentando conversão para: {final_mp3_path}")
    print(f"🐛 Debug (ffmpeg_path): {ffmpeg_path}")
    print(f"🐛 Debug (output_path_str for ytdl-p): {output_path_str}")

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])

        if os.path.exists(final_mp3_path) and os.path.getsize(final_mp3_path) > 0:
            print(f"\n✅ Download e conversão para MP3 concluídos!")
            print(f"   MP3 salvo em: {final_mp3_path}")
        else:
            print(f"\n❌ ERRO: Arquivo MP3 final ({final_mp3_path}) não encontrado ou está vazio.")
            print(f"   Verifique os logs do yt-dlp e ffmpeg acima.")
            # List files in output directory for debugging
            try:
                files_in_output = os.listdir(output_path_str)
                print(f"   Conteúdo da pasta de destino ({output_path_str}): {files_in_output}")
            except Exception as e_ls:
                print(f"   Não foi possível listar conteúdo da pasta de destino: {e_ls}")

    except yt_dlp.utils.DownloadError as e_dl:
        print(f"\n❌ Erro de Download com yt-dlp: {str(e_dl)}")
        if hasattr(e_dl, 'exc_info') and e_dl.exc_info and e_dl.exc_info[1]:
            inner_exception = e_dl.exc_info[1]
            print(f"   Exceção interna: {type(inner_exception).__name__}: {str(inner_exception)}")
        print(f"   Verifique a URL e sua conexão com a internet.")
    except Exception as e_main:
        print(f"\n❌ Erro inesperado durante o download ou conversão: {str(e_main)}")
        import traceback
        traceback.print_exc()
        print(f"   Verifique os logs do ffmpeg acima.")

def download_video(url: str, output_path: str, ffmpeg_path: str) -> None:
    ydl_opts = {
        'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        'outtmpl': os.path.join(output_path, '%(title)s.%(ext)s'),
        'verbose': True,
        'noprogress': False,
        'ffmpeg_location': ffmpeg_path,  # Usa o caminho do ffmpeg do pyffmpeg
        'progress_hooks': [lambda d: print_progress(d)],
        'writedescription': False,
        'writeinfojson': False,
        'writethumbnail': False,
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
        'writedescription': False,
        'writeinfojson': False,
        'writethumbnail': False,
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
    # Obtém o caminho do ffmpeg
    ffmpeg_path = get_ffmpeg_path()
    if not ffmpeg_path: # Check if ffmpeg_path is None (not found)
        print("❌ ERRO CRÍTICO: Caminho do ffmpeg não pôde ser determinado. O download de áudio/vídeo falhará na conversão.")
        # Allow to continue so user can see the error, but downloads requiring ffmpeg will fail
    
    # Clear any initial stdin buffer issues
    clear_stdin_buffer()
    
    while True:
        print("\n" + "="*50)
        print("📺 AQUISIÇÃO DE CONTEÚDO DO YOUTUBE")
        print("="*50)
        print("1. 🎵 Baixar Somente Áudio (MP3)")
        print("2. 🎥 Baixar Vídeo (Melhor Qualidade)")
        print("3. 🎬 Baixar Vídeo (Otimizado para Pro Tools)")
        print("0. ↩️ Voltar ao Menu Principal")

        try:
            # Clear buffer before reading input
            clear_stdin_buffer()
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print("\nDigite sua escolha (0-3):")
            choice = input("➤ ").strip()
            print(f"🐛 Debug: Escolha do menu: '{choice}'")  # Debug output

            if choice == "0":
                print("✅ Saindo do YouTube Downloader.")
                break
                
            elif choice in ["1", "2", "3"]:
                action_names = ["", "🎵 Baixar Áudio", "🎥 Baixar Vídeo", "🎬 Vídeo para Pro Tools"]
                print(f"\n📝 Opção selecionada: {action_names[int(choice)]}")
                
                url = get_url()
                if not url:
                    print("❌ URL não fornecida ou operação cancelada.")
                    continue
                
                print(f"🐛 Debug: URL validada: '{url}'")  # Debug output
                
                output_path = get_output_path()
                if output_path is None:
                    print("❌ Caminho de saída não fornecido ou operação cancelada.")
                    continue
                
                print(f"🐛 Debug: Caminho de saída: '{output_path}'")  # Debug output
                
                # Verifica novamente se temos o caminho do ffmpeg
                if not ffmpeg_path: # Check if ffmpeg_path is None
                    print("⚠️ Aviso: O caminho do ffmpeg não está disponível. A conversão para MP3 ou outros formatos falhará.")
                
                print(f"\n🚀 Iniciando download...")
                if choice == "1":
                    download_audio(url, output_path, ffmpeg_path)
                elif choice == "2":
                    download_video(url, output_path, ffmpeg_path)
                else:
                    download_video_protools(url, output_path, ffmpeg_path)
                    
            else:
                print(f"❌ Opção inválida: '{choice}'. Por favor, digite uma opção válida (0-3)")
                
        except (EOFError, KeyboardInterrupt):
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print("\n⚠️ Operação interrompida pelo usuário.")
            break
        except Exception as e:
            sys.stdout.flush() # Flush stdout
            sys.stderr.flush() # Flush stderr
            print(f"\n❌ Erro inesperado no menu: {str(e)}")
            import traceback
            traceback.print_exc()
            
        # Clear buffer before asking to continue
        clear_stdin_buffer()
        sys.stdout.flush() # Flush stdout
        sys.stderr.flush() # Flush stderr
        print(f"\n{'='*50}")
        print("Pressione Enter para continuar...")
        input("➤ ")

if __name__ == "__main__":
    # Instalando dependências (isso também é feito no início do script)
    try:
        import yt_dlp
    except ImportError:
        print("Instalando yt-dlp...")
        subprocess.call([sys.executable, "-m", "pip", "install", "yt-dlp"])
        import yt_dlp
    
    main_menu() 