import sys
import os
import subprocess
import click
import logging

# Get the directory path of this file
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
workflow_dir = os.path.join(base_dir, "workflow")

logging.basicConfig(level=logging.INFO)

def get_snakefile(file="Snakefile"):
    snake_file = os.path.join(workflow_dir, file)
    if not os.path.exists(snake_file):
        sys.exit("Unable to locate the  Snakefile;  tried %s" % snake_file)
    return snake_file

def get_configfile(file="config.yaml"):
    config_file = os.path.join(workflow_dir, "config", file)
    if not os.path.exists(config_file):
        sys.exit("Unable to locate the config.yaml file;  tried %s" % config_file)
    return config_file

def show_help_message():
    message = (
        "\nUsage examples:\n"
        "\n    kgwasflow run [OPTIONS]         Run the kGWASflow workflow\n"
        "\n    kgwasflow test [OPTIONS]        Run the kGWASflow test\n"
        "\n    kgwasflow --help"
        "\n\nRun examples:"
        "\n\n1. Run kGWASflow with the default config file (../config/config.yaml), default snakemake arguments and 16 threads:\n"
        "\n    kgwasflow run -t 16 --snake-default"
        "\n\n2. Run kGWASflow with a custom config file (path/to/custom_config.yaml) and default settings:\n"
        "\n    kgwasflow run -t 16 -c path/to/custom_config.yaml"
        "\n\n3. Run kGWASflow with user defined output directory:\n"
        "\n    kgwasflow run -t 16 --output path/to/output_dir"
        "\n\n4. Run kGWASflow in dryrun mode to see what tasks would be executed without actually running them:\n"
        "\n    kgwasflow run -t 16 -n"
        "\n\n5. Run kGWASflow using mamba as the conda frontend:\n"
        "\n    kgwasflow run -t 16 --conda-frontend mamba"
        "\n\n6. Run kGWASflow and generate an HTML report:\n"
        "\n    kgwasflow run -t 16 --generate-report"
        "\n\nTest examples:"
        "\n\n1. Run the kGWASflow test in dryrun mode to see what tasks would be executed:\n"
        "\n    kgwasflow test -t 16 -n"
        "\n\n2. Run the kGWASflow test using the test config file with 16 threads:\n"
        "\n    kgwasflow test -t 16"
        "\n\n3. Run the kGWASflow test and define the test output folder:\n"
        "\n    kgwasflow test -t 16  --output path/to/test_output_dir"
    )
    return message


def show_ascii_art():
    click.echo("""
    \b           
     _     _______          __      _____  __ _               
    | |   / ____\ \        / /\    / ____|/ _| |              
    | | _| |  __ \ \  /\  / /  \  | (___ | |_| | _____      __
    | |/ / | |_ | \ \/  \/ / /\ \  \___ \|  _| |/ _ \ \ /\ / /
    |   <| |__| |  \  /\  / ____ \ ____) | | | | (_) \ V  V / 
    |_|\_\\_____|   \/  \/_/    \_\_____/|_| |_|\___/ \_/\_/  
    \b
    kGWASflow: A Snakemake Workflow for k-mers Based GWAS
    """)

def run_snake(snakefile, config_file, threads, output, conda_frontend, dryrun, generate_report, snake_default, rerun_triggers, verbose, unlock, snakemake_args):
    # Define the command to run snakemake
    cmd = ['snakemake', '--use-conda', '--conda-frontend', conda_frontend, '--cores', str(threads)]

    if snakefile:
        cmd += ['--snakefile', snakefile]
    
    # if config file is provided, use it
    if config_file:
        cmd += ['--configfile', config_file]
        
    # if output directory is provided, use it
    if output:
        if not os.path.exists(output):
            os.makedirs(output)
        cmd += ['--directory', output]
        
    if dryrun:
        cmd.append('--dryrun')

    if generate_report:
        if dryrun:
            cmd.append('--report')
            cmd.append('kGWASflow-report.html')
        if not dryrun:
            cmd.append('--dryrun')
            cmd.append('--report')
            cmd.append('kGWASflow-report.html')
    
    if snakemake_args:
        cmd += snakemake_args
    
    if rerun_triggers:
        cmd += ['--rerun-triggers'] + list(rerun_triggers)
    
    if snake_default:
        default_snakemake_args = ["--rerun-incomplete", "--printshellcmds", "--nolock", "--show-failed-logs"]
        cmd += default_snakemake_args
    
    if verbose:
        cmd.append('--verbose')
        
    if unlock:
        cmd.append('--unlock')
    
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        logging.error("Error running Snakemake: {}".format(e))