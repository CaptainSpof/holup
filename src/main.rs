use clap::{AppSettings, Clap};
use console::Term;
use dialoguer::Confirm;
use easy_reader::EasyReader;
use std::process::Command;
use std::{fs::File, io::Error, path::PathBuf};

use random_ramble::refactor::RandomRamble;

/// holup is a simple CLI tool that prompts a message asking for confirmation before running a command.
#[derive(Clap)]
#[clap(version = "1.0", author = "CaptainSpof <captainspof@gmail.com>")]
#[clap(setting = AppSettings::ColoredHelp)]
struct Opts {
    // /// Sets a custom config file. Could have been an Option<T> with no default too
    // #[clap(short, long)]
    // config: Option<String>,
    /// The command to run.
    command: String,
    // /// A level of verbosity, and can be used multiple times
    // #[clap(short, long, parse(from_occurrences))]
    // verbose: i32,
    /// Confirmation templates to be used with the <command>
    #[clap(short, long, default_value = "{{ sentence | rr }}\nRun {{ cmd | rr }}?")]
    templates: Vec<String>,
    /// A confirmation sentence to be used with the <command>
    #[clap(short, long)]
    sentence: Option<String>,
    /// A path to snarky sentences
    #[clap(short = 'p', long, default_value = "templates/sentences")]
    sentences_path: PathBuf,
}

fn main() {
    let opts: Opts = Opts::parse();

    let command = opts.command;

    let holup = RandomRamble::new()
        .with_templates(opts.templates.iter().map(AsRef::as_ref).collect())
        .with_other("cmd", &command)
        .with_others(
            "confirmation",
            vec![
                &format!("\nAre you sure, you want to run {}!?", command),
                &format!("\nRun {}? Do it!", command),
                &format!("\nExec {}? I dare you!", command)
            ]
        )
        .with_others_path("sentence", &opts.sentences_path)
        .expect("couldn't load other path, I guess…")
        .build()
        .unwrap()
        .to_string();

    prompt_stdin(&holup, &command);

    // let sass = match get_sass(&opts.sentences_path) {
    //     Err(e) => {
    //         eprintln!("{}", e);
    //         std::process::exit(1);
    //     }
    //     Ok(sass) => sass,
    // };

    // match opts.sentence {
    //     Some(s) => prompt_stdin(&s, &command),
    //     None => prompt_stdin(&format!("{}\nRun {} ?", sass, command), &command),
    // };
}

fn prompt_stdin(prompt_str: &str, cmd: &str) {
    let term = Term::stderr();

    if Confirm::new()
        .with_prompt(prompt_str)
        .interact_on(&term)
        .unwrap()
    {
        if !cmd.is_empty() {
            Command::new(cmd)
                .spawn()
                .expect("failed to execute process");
        }
    } else {
        println!("C'est toi qui voit poto.");
        std::process::exit(1)
    }
}

// fn get_sass(path: &PathBuf) -> Result<String, Error> {
//     let file = File::open(path)?;
//     let mut reader = EasyReader::new(file)?;

//     Ok(reader.random_line()?.expect("Bummer"))
// }
