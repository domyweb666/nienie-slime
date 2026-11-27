import sys
sys.stdout.reconfigure(encoding='utf-8')
p=sys.argv[1]
try:
    import pypdf
    r=pypdf.PdfReader(p); t='\n'.join((pg.extract_text() or '') for pg in r.pages)
except Exception as e:
    try:
        import fitz
        d=fitz.open(p); t='\n'.join(pg.get_text() for pg in d)
    except Exception as e2:
        from pdfminer.high_level import extract_text
        t=extract_text(p)
open(sys.argv[2],'w',encoding='utf-8').write(t); print(len(t))
